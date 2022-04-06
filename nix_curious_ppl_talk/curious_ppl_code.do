* Replication code for MSU & Curious People presentations
* Last updated 3/16/22

* Uncomment & install cleanplot scheme if you want
	* net install cleanplots, from("https://tdmize.github.io/data/cleanplots")
	* set scheme cleanplots, perm

* Call up the data from WAPO's github repo
	import delimited "https://raw.githubusercontent.com/washingtonpost/data-police-shootings/master/fatal-police-shootings-data.csv", clear

* destring the date variable & create year, month, and day variables
	gen oisdate = date(date, "YMD")
	format oisdate %td
	
	gen year  = year(oisdate)
	gen month = month(oisdate)
	gen daily = doy(oisdate)
	gen fois = 1
	
* end the time series at 2021
	drop if year == 2022
	
* Figure 1. Daily scatter plots for each year with 7-day smoothers
	
preserve
	
	collapse (sum) fois (mean) year, by(oisdate)
	
	tsset oisdate
	tsfill 
	
	replace fois = 0 if fois == .
	
	* First shooting was on Jan 2 2015, so need to add a 0 for Jan 1
		set obs 2557
		replace oisdate = 20089 in 2557
		replace year = 2015 in 2557
		replace fois = 0 if oisdate == 20089
		sort oisdate
	
	* Also need to backfill the missing years from the tsfill command
		gen year2 = year(oisdate)
		drop year
		rename year2 year
	
	* Generate a 7-day smoother (3 days before, day, 3 days after)
		gen smooth7 = (fois[_n-3]+fois[_n-2]+fois[_n-1]+ ///
			fois[_n]+ ///
			fois[_n+3]+fois[_n+2]+fois[_n+1])/7
			
	* Run a loop tha tplots 2015-20
		forval i = 2015(1)2020 {
			twoway scatter fois oisdate if year == `i', mc(%35) || line smooth7 oisdate if year == `i', lc(blue) lw(medthick) yscale(range(0(5)10)) ylabel(0(5)10, labs(vsmall)) ymtick(1(1)10) leg(off) name(y`i', replace) plotr(margin(0 0 0 0)) graphr(margin(1 1 2 2)) xlabel(none) xtitle("") xscale(off fill) ytitle({bf:`i'}, size(small)) nodraw
			}
		
	* Now, create the 2021 plot with an x axis
		twoway scatter fois oisdate if year == 2021, mc(%35) ///
			|| line smooth7 oisdate if year == 2021, lc(blue) lw(medthick) ///
				yscale(range(0(5)10)) ylabel(0(5)10, labs(vsmall)) ymtick(1(1)10) ytitle("{bf:2021}", size(small)) ///
				tscale(range(01jan2021 31dec2021)) tlabel(01jan2021 01feb2021 01mar2021 01apr2021 01may2021 01jun2021 01jul2021 01aug2021 01sep2021 01oct2021 01nov2021 01dec2021, nogrid format(%tdm) labs(small)) xtitle("") ///
				leg(off) plotr(margin(0 0 0 0)) graphr(margin(1 1 0 0)) name(y2021, replace) nodraw
				
	* Now, combine them all
		graph combine y2015 y2016 y2017 y2018 y2019 y2020 y2021, rows(7) title("Fatal Police Shootings Per Day, 2015-2021", size(small)) subtitle("Source: WAPO (accessed 3/16/2022)", size(vsmall)) note("* NOTE: Blue line is rolling 7-day mean", size(vsmall) pos(5) margin(0 0 0 2))
		
restore

* Figure 2. Decedent sex
	graph bar (sum) fois, by(gender, note("* NOTE: Sex missing for 4 decedents", size(vsmall) pos(5) margin(0 0 0 2))) ytitle("Count", size(medsmall)) blabel(total, pos(outside) size(medsmall))

* Figure 3. Age distribution
	hist age if year < 2021, freq ytitle("Count", size(medsmall)) xtitle("Age", size(medsmall)) xscale(range(0(10)100)) xlabel(0(10)100, labs(small)) xmtick(5(5)95) title("Decedent Age Distribution, 2015-2020", size(medsmall)) width(1) note("* NOTE: Age missing for 239 decedents", size(vsmall) pos(5) margin(0 0 0 2))
	
* Figure 4. Race breakdown
	gen asian = 1 if race == "A"
	replace asian = 0 if race != "A" & race != ""
	
	gen black = 1 if race == "B"
	replace black = 0 if race != "B" & race != ""
	
	gen hispanic = 1 if race == "H"
	replace hispanic = 0 if race != "H" & race != ""
	
	gen native = 1 if race == "N"
	replace native = 0 if race != "N" & race != ""
	
	gen other = 1 if race == "O"
	replace other = 0 if race != "O" & race != ""
	
	gen white = 1 if race == "W"
	replace white = 0 if race != "W" & race != ""
	
	graph bar (mean) white black hispanic asian native other if year < 2021, ytitle("Percent", size(medsmall)) blabel(total, pos(outside) size(medsmall)) blabel(total, pos(outside) format(%4.2f)) ytitle("Proportion of Total", size(medsmall)) leg(off) showyvars yvar(relabel(1 "White" 2 "Black" 3 "Hispanic" 4 "Asian" 5 "Native American" 6 "Other")) bargap(5) title("Decedent Race/Ethnicity Breakdown, 2015-2020", size(medsmall)) note("* NOTE: Race/ethnicity missing for 474 decedents", size(vsmall) pos(5) margin(0 0 0 2))
	
* Figure 4. Weapon
	tab armed
	
	gen gun = 1 if regexm(armed, "gun") == 1
		tab armed if gun == 1
	replace gun = 0 if gun == 1 & (regexm(armed, "pellet") == 1 | regexm(armed, "BB") == 1 | regexm(armed, "bean-bag") == 1 | regexm(armed, "nail") == 1)
	replace gun = 0 if gun == . 
	
	gen unarmed = 1 if armed == "unarmed"
	replace unarmed = 0 if unarmed != 1	
	
	gen other_weap = 1 if gun == 0 & unarmed == 0
	replace other_weap = 0 if other_weap != 1 
	
	gen undetermined = 1 if armed == "" | armed == "undetermined"
	replace undetermined = 0 if undetermined != 1
	
	graph bar (mean) gun other_weap unarmed if year < 2021, blabel(total, pos(outside) format(%4.2f)) ytitle("Proportion of Total", size(medsmall)) leg(off) showyvars yvar(relabel (1 "Gun" 2 "Other Weapon/Object" 3 "Unarmed")) bargap(10) title("Weapon Breakdown, 2015-2020", size(medsmall)) note("* NOTE: Undetermined weapon for 331 decedents", size(vsmall) pos(5) margin(0 0 0 2))
	
* Figure 5. Threat level
	gen attack = 1 if threat_level == "attack"
	replace attack = 0 if threat_level == "other"
	
	gen other_threat = 1 if threat_level == "other"
	replace other_threat = 0 if threat_level == "attack"

	graph bar (mean) attack other_threat if year < 2021, blabel(total, pos(outside) format(%4.2f)) ytitle("Proportion of Total", size(medsmall)) leg(off) showyvars yvar(relabel (1 "Imminent Threat" 2 "Other")) bargap(30) title("Threat Posed by Decedents, 2015-2020", size(medsmall)) note("* NOTE: Undetermined threat level for 160 decedents", size(vsmall) pos(5) margin(0 0 0 2))
	
* Figure 6. Weapon X Threat
	graph bar (mean) attack other_threat if gun == 1 & threat_level != "undetermined" & year < 2021, over(gun, relabel(1 " ")) blabel(total, pos(inside) format(%4.2f) size(medsmall)) ytitle("Proportion of Total", size(medsmall)) leg(off) showyvars yvar(relabel (1 "Imminent Threat" 2 "Other")) bargap(10) title("{bf:Armed with Gun}", size(medsmall)) name(gun, replace) nodraw
	
	graph bar (mean) attack other_threat if other_weap == 1 & threat_level != "undetermined" & year < 2021, over(other_weap, relabel(1 " ")) blabel(total, pos(inside) format(%4.2f) size(medsmall)) ytitle("") leg(off) showyvars yvar(relabel (1 "Imminent Threat" 2 "Other")) bargap(10) title("{bf:Armed with Other Weapon/Object}", size(medsmall)) name(other_weap, replace) nodraw
	
	graph bar (mean) attack other_threat if unarmed == 1 & threat_level != "undetermined" & year < 2021, over(unarmed, relabel(1 " ")) blabel(total, pos(inside) format(%4.2f) size(medsmall)) ytitle("") leg(off) showyvars yvar(relabel (1 "Imminent Threat" 2 "Other")) bargap(10) title("{bf:Unarmed}", size(medsmall)) name(unarmed, replace) nodraw
	
	graph combine gun other_weap unarmed, rows(1) ycommon note("* NOTE: Undetermined weapon and/or threat level for 318 decedents", size(vsmall) pos(5) margin(0 0 0 2))
	
* Figure 7. Mental illness
preserve

	gen mental_illness = 1 if signs_of_mental_illness == "True"
	replace mental_illness = 0 if signs_of_mental_illness == "False"
	
	collapse (mean) mental_illness, by(year)
	
	gen pct_mental_illness = 100*mental_illness
	
	graph bar pct_mental_illness if year < 2021, over(year) ytitle("% of Total", size(medsmall)) blabel(total, pos(outside) format(%4.1f) size(small)) yscale(range(0(10)30)) ylabel(0(10)30)
	
restore

* Figure 8. Fatality rates in 46 largest departments (From VICE)
	import delimited "https://raw.githubusercontent.com/vicenews/shot-by-cops/master/subject_data.csv", clear
	
	gen fatality = 1 if regexm(fatal, "F") == 1
	replace fatality = 0 if fatality != 1 & fatal != "U"
	
	gen nonfatal = 1 if regexm(fatal, "N") == 1
	replace nonfatal = 0 if nonfatal != 1 & fatal != "U"
	
	collapse (sum) fatality nonfatal, by(city)
	
	gen rate = (fatality/(fatality+nonfatal))*100
	
	graph bar rate, over(city, sort(1) descending lab(labs(vsmall) angle(45))) nofill blabel(total, pos(outside) size(vsmall) orient(vertical) format(%4.0f)) ytitle("Fatality Rate", size(medsmall)) title("Police Shooting Fatality Rates, 2010-16", size(medsmall)) note("* NOTE: Detroit had 111 police shootings over this period but did not indicate their outcomes.", size(vsmall) pos(5) margin(0 0 0 2))

* Figure 9. Highlight the examples I've used before on my blog
	* Las Vegas v. St. Louis
	
		separate rate, by(city == "LasVegas" | city == "St. Louis")
		
		graph bar rate0 rate1, over(city, sort(rate) descending lab(labs(vsmall) angle(45)))nofill blabel(total, pos(outside) size(vsmall) orient(vertical) format(%4.0f)) ytitle("Fatality Rate", size(medsmall)) title("Police Shooting Fatality Rates, 2010-16", size(medsmall)) note("* NOTE: Detroit had 111 police shootings over this period but did not indicate their outcomes.", size(vsmall) pos(5) margin(0 0 0 2)) leg(off) text(58 65 "Vegas had 47 fatal shootings ({bf:115 total})") text(50 65 "St. Louis had 20 fatal shootings ({bf:119 total})")
		
		drop rate0 rate1
		
		separate rate, by(city == "Atlanta" | city == "Boston")
		
		graph bar rate0 rate1, over(city, sort(rate) descending lab(labs(vsmall) angle(45)))nofill blabel(total, pos(outside) size(vsmall) orient(vertical) format(%4.0f)) ytitle("Fatality Rate", size(medsmall)) title("Police Shooting Fatality Rates, 2010-16", size(medsmall)) note("* NOTE: Detroit had 111 police shootings over this period but did not indicate their outcomes.", size(vsmall) pos(5) margin(0 0 0 2)) leg(off) text(58 65 "Boston had 10 fatal shootings ({bf:14 total})") text(50 65 "Atlanta had 10 fatal shootings ({bf:43 total})")

* Figure 10. Cops killed by knives or blunt objects each year 
* (2010-19 figures from https://ucr.fbi.gov/leoka/2019/tables/table-28.xls)
* (2020-21 figures from the December monthly infographics available for download here: https://crime-data-explorer.app.cloud.gov/pages/le/leoka)
clear

set obs 12

gen year = _n + 2009

gen knife = 0
replace knife = 1 if year == 2011
replace knife = 1 if year == 2012
replace knife = 1 if year == 2017
replace knife = 2 if year == 2021

gen blunt_obj =  0

gen pers_weap = 0
replace pers_weap = 2 if year == 2011
replace pers_weap = 2 if year == 2012
replace pers_weap = 1 if year == 2014
replace pers_weap = 1 if year == 2020
replace pers_weap = 4 if year == 2021

gen gun = .
replace gun = 54 if year == 2010
replace gun = 63 if year == 2011
replace gun = 44 if year == 2012
replace gun = 26 if year == 2013
replace gun = 46 if year == 2014
replace gun = 38 if year == 2015
replace gun = 62 if year == 2016
replace gun = 42 if year == 2017
replace gun = 52 if year == 2018
replace gun = 44 if year == 2019
replace gun = 42 if year == 2020
replace gun = 61 if year == 2021

graph bar gun knife blunt_obj pers_weap, over(year) leg(pos(6) rows(1) label(1 "Gun") label(2 "Knife") label(3 "Blunt Object") label(4 "Hands/Fist/Feet/Etc")) blabel(total, pos(outside) size(small)) title("Law Enforcement Officers Feloniously Killed, 2010-2021") subtitle("By Type of Weapon Used")