exit

* load data --------------------------------------------------------------------

set more off

cd "~/Git/signalundrauschen/"

use "input/master_nation_stata.dta", clear

* ------------------------------------------------------------------------------
* Possible random coeff. models (actual estimation happens further down)  
* ------------------------------------------------------------------------------

* xtmixed voteshare // empty model

* xtmixed voteshare || state: // empty model with random intercept for states

* xtmixed voteshare || state: || party:  // empty model random intercept for states and parties

* xtmixed voteshare || party: || state:  // empty model random intercept for states and parties

* xtmixed voteshare || _all:R.party || state:  // empty model random intercept for states and parties (crossclassified)


* ------------------------------------------------------------------------------
* Out-of-sample forecasts
* ------------------------------------------------------------------------------

* ------------------------------------------------------------------------------
* For out-of-sample forecasts run from here to... ------------------------------

cap gen voteshare_se = .

* This estimates models over sample before the years 1998, 2002, 2005, 2009, 2013
* and 2017 and then predict vote shares for the respective years

set more off
foreach year in 1998 2002 2005 2009 2013 2017 {
	di `year'
	quietly: mixed voteshare voteshare_l voteshare_state  pm_party gpya_l pm_partyXgpya_l pmyears pmyearsXpm_party || state: voteshare_state  || party: if elec_year < `year' & state != "Bundesgebiet", mle covariance(unstructured)
	
	predict prtmp, fitted
	replace voteshare_hat = prtmp if elec_year == `year' & state != "Bundesgebiet"
	drop prtmp
	predict stdptmp, stdp
	replace voteshare_se = stdptmp if elec_year == `year' & state != "Bundesgebiet"
	drop stdptmp
	* weighted
	* mixed voteshare voteshare_l voteshare_state  pm_party gpya_l pm_partyXgpya_l pmyears pmyearsXpm_party [pw=timewt]  || state: voteshare_state || party: if state != "Bundesgebiet", mle covariance(unstructured)
	* predict prtmp, fitted
	* replace voteshare_hat_w = prtmp if elec_year == `year' & state != "Bundesgebiet"
	* drop prtmp
}


* Aggregation to national result ------------------------------------------------

* for 2017 turnout needs to be forecasted as well
* this is reason for merging in turnout forecasts

* calculate predicted voteshare for AfD
* 2017
bysort state: egen voteshare_hat_parties = sum(voteshare_hat) if elec_year == 2017 & state != "Bundesgebiet"
bysort state: gen voteshare_hat_afd = 100 - voteshare_hat_parties if elec_year == 2017 & state != "Bundesgebiet"
replace voteshare_hat = voteshare_hat_afd if party == "afd" & elec_year == 2017 & state != "Bundesgebiet"
drop voteshare_hat_parties voteshare_hat_afd
* 2013
bysort state: egen voteshare_hat_parties = sum(voteshare_hat) if elec_year == 2013 & state != "Bundesgebiet"
bysort state: gen voteshare_hat_afd = 100 - voteshare_hat_parties if elec_year == 2013 & state != "Bundesgebiet"
replace voteshare_hat = voteshare_hat_afd if party == "afd" & elec_year == 2013 & state != "Bundesgebiet"

list state party voteshare_hat voteshare_hat_parties voteshare_hat_afd if elec_year == 2017

* calculate the number of valid votes for 2017
replace valid = turnout_pred * electorate if elec_year == 2017

* list state party elec_year turnout_pred valid electorate if elec_year >= 2013

* calculate the number of votes received by a party
replace votes_hat = voteshare_hat/100 * valid if state != "Bundesgebiet"
* replace votes_hat_w = voteshare_hat_w/100 * valid if state != "Bundesgebiet"  // weighted model

* sum the votes received by a party by election (therefore summing over
* state results of parties)
cap drop votes_hat_party votes_hat_party_w
bysort elec_year party: egen votes_hat_party = total(votes_hat) 
replace  votes_hat_party = . if state != "Bundesgebiet"
* bysort elec_year party: egen votes_hat_party_w = total(votes_hat_w)  // weighted model
* replace  votes_hat_party_w = . if state != "Bundesgebiet"  // weighted model

* calculate the total number of valid votes nationwide 
cap drop votes_hat_national votes_hat_national_w
by elec_year: egen votes_hat_national = total(votes_hat_party)
replace votes_hat_national = . if elec_year < 1998 | state != "Bundesgebiet"
* by elec_year: egen votes_hat_national_w = total(votes_hat_party_w)  // weighted model
* replace votes_hat_national_w = . if elec_year < 1998 | state != "Bundesgebiet"  // weighted model

* Estimate vote share at national level
replace voteshare_hat = votes_hat_party / votes_hat_national * 100 if state == "Bundesgebiet"
* replace voteshare_hat_w = votes_hat_party_w / votes_hat_national_w * 100 if state == "Bundesgebiet"

* list state party elec_year voteshare voteshare_hat if elec_year >= 2013


* Calculate errors -------------------------------------------------------------

replace error = voteshare_hat - voteshare // error up until 2013 (no voteshares for 2017)
* replace error_w = voteshare_hat_w - voteshare // error up until 2013 (no voteshares for 2017) (weighted model)
replace error_abs = abs(error)
* replace error_abs_w = abs(error_w)  // (weighted model)
replace error2 = error^2
* replace error2_w = error_w^2  // (weighted model)
replace error_abs_bigp = error_abs if party == "cdu_csu" | party == "spd"
replace error2_bigp = error2 if party == "cdu_csu" | party == "spd"

replace error_abs_wnelec = error_abs * wnelec
replace error2_wnelec = error2 * wnelec
replace error_abs_w2 = error_abs * w2
replace error2_w2 = error2 * w2

replace error2017 = voteshare_hat - poll if elec_year == 2017 & state == "Bundesgebiet"
replace error2017_abs = abs(error2017)
* replace error2017_w = voteshare_hat_w - poll if elec_year == 2017 & state == "Bundesgebiet"
* replace error2017_abs_w = abs(error2017_w)
replace error2017_2 = error2017^2


* ... here ---------------------------------------------------------------------
* ------------------------------------------------------------------------------

preserve
keep if elec_year >= 1998 & elec_year <= 2013 & state == "Bundesgebiet"
bysort party: sum error2 
restore

list elec_year party voteshare_hat voteshare if elec_year >= 1998 & elec_year <= 2013 & state == "Bundesgebiet"

* ------------------------------------------------------------------------------
* For evaluation of 2017 forecasts run from here to ... ---------------

list party voteshare_hat poll if elec_year == 2017 & state == "Bundesgebiet"

sum error2017* if elec_year == 2017 & state == "Bundesgebiet"

* ... here ---------------------------------------------------------------------

* ------------------------------------------------------------------------------
* Save changed data
* ------------------------------------------------------------------------------

saveold "input/master_nation_forecast.dta", replace
