Signal und Rauschen
===================

Dieses Repository enthält die Daten hinter den Visualisierungen auf https://signalundrauschen.de/. Außerdem stellen wir hier den Code bereit, der die Daten sammelt und aufbereitet.

Was findest Du im Repository
----------------------------

Dieses Repository enthält sämtliche Daten hinter den Visualisierungen auf https://signalundrauschen.de/. Den Code hinter den Visualisierungen (S&R nutzt D3.js) findest Du hier allerdings nicht - dafür war nicht der Inhaber dieses Repos verantwortlich.

`umfragedaten.csv` enthält alle Umfragewerte im [tidy data](https://en.wikipedia.org/wiki/Tidy_data)-Format (Sozialwissenschaftler kennen es auch als 'long format'). Eine Zeile enthält den Umfragewert eines Instituts für eine Partei.

`schnitt1.csv` enthält die Daten, die als 'Umfrageschnitt pur' visualisiert werden. Diese werden von `03_schnitt1.R` aus dem `umfragedaten.csv` aggregiert.

`schnitt2.csv` enthält die Daten, die als Umfrageschnitt pur visualisiert werden. Diese werden von `04_schnitt2.R` aus dem `umfragedaten.csv` aggregiert.

Methodologie
------------

Hier findest Du erläutert wie wir die Umfragedaten zusammenfassen. Diesen Text findest Du auch auf https://signalundrauschen.de/methode/.

### Kurzerklärung in 200 Zeichen/Modell:

**Umfrageschnitt pur:** Arithmetisches Mittel (Durchschnitt) aller Umfragen einer Woche.

**S&R-Umfrageschnitt:** Gewichteter tagesaktueller Durchschnitt der Umfragen der letzten zwei Wochen. Gewichtung: Zeitpunkt der Befragung, Stichprobengröße & Fehlerquote der Umfrageunternehmen vor den letzten 5 Bundestagswahlen

### Und ausführlich:

**Stufe 1: Umfrageschnitt pur**
In der Grafik auf der Titelseite zeigen wir unter „Umfrageschnitt pur“ das arithmetische Mittel aller Umfragen der wichtigsten Institute. Wir geben diese Zahlen 1:1 ungewichtet wieder, heißt also: pro Wochen haben wir alle Umfragen zusammengerechnet und den Durchschnitt gebildet.
Berücksichtigt werden Umfragen von Allensbach, Emnid, Forsa, Forschungsgruppe Wahlen, GMS, Infratest dimap und INSA. Die Daten sind von wahlrecht.de.

**Stufe 2:  S&R-Umfrageschnitt**
Diese zweite Stufe ist unsere Standardansicht. Hier zeigen wir einen gewichteten tagesaktuellen rollierenden Durchschnitt. Dazu berechnen wir eine gewichtetes arithmetisches Mittel der Umfragen der vorhergehenden 20 Tage. Wir nutzen dabei drei Gewichtungsfaktoren: der Zeitpunkt der Befragung, die Stichprobengröße und die Abweichung der letzten Vorwahlbefragungen der Umfrageunternehmen vor den tatsächlichen Ergebnissen der letzten fünf Bundestagswahlen. Das heißt: Neuere Umfragen und solche mit mehr Befragten fließen stärker in unseren Schnitt ein. Die Gewichtung auf Basis des letzten Tags der Befragung folgt einer logistischen Funktion: während Umfragen der ersten Woche noch stark einfließen, bekommen Umfragen der vorletzten Woche kaum Gewicht mehr. Die Gewichtung auf Basis der Stichprobengröße erfolgt über Berechnung der sogenannten t-Statistik. Diese wird benötigt, um Konfidenzintervalle zu berechnen, welche die statistische Unsicherheit in Umfragewerten quantifzieren. Für die Fehlerquote haben wir die mittlere quadratische Abweichung eines Unternehmens vor den tatsächlichen Stimmanteilen der Parteien in den letzten fünf Bundestagswahlen berechnet. Heißt in der Praxis: Wenn ein Unternehmen in der Vergangenheit eine bestimmte Partei zu hoch oder zu niedrig eingeschätzt hat, dann geben wir den Umfragewerten dieses Unternehmens für diese Partei ein geringeres Gewicht. Oder andersherum: Wenn ein Unternehmen eine Partei in der Vergangenheit besonders treffsicher eingeschätzt hat, fließen die aktuellen Umfragewerte dieses Instituts zu dieser Partei stärker in unsere S&R-Umfrageschnitt-Werte ein.
Berücksichtigt werden auch hier Umfragen von Allensbach, Emnid, Forsa, Forschungsgruppe Wahlen, GMS, Infratest dimap, INSA. Die Daten sind von wahlrecht.de. Die Berechnungen und den Rechenweg mit Abweichungen aus der Vergangenheit werden im Magazin in Kürze noch näher beschreiben. Wer will, kann dann selbst mit den CSV-Dateien und dem Skript (in R) experimentieren.
