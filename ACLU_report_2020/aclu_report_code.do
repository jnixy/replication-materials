********************************************************************************************************
* ANALYZE WAPO'S FATAL FORCE DATA FOR ACLU REPORT
* Last performed 7/13/2020, so note that for figures, labels for X & Y axes will need to be updated
* Figure 4 requires Michael Stepner's -maptile- and -spmap- commands
	* See https://michaelstepner.com/maptile/
********************************************************************************************************

import delimited "https://raw.githubusercontent.com/washingtonpost/data-police-shootings/master/fatal-police-shootings-data.csv", clear

* directory for figures/charts
	cd "~\Figures"

* destring the date variable & create various calendar variables
	gen oisdate = date(date, "YMD")
	format oisdate %td
	
	gen year  = year(oisdate)
	gen month = month(oisdate)
	gen monthly = ym(year, month) // jan2015 = 660, april2020 = 723
	format monthly %tm
	gen daily = doy(oisdate)
	gen woy = week(oisdate)
	
* create variable that counts # of days since 1/1/2015
	gen start_date = mdy(1, 1, 2015)
	gen day = oisdate - start_date
	
* destring race variable
	gen race2 = .
	replace race2 = 1 if race == "W"
	replace race2 = 2 if race == "B"
	replace race2 = 3 if race == "H"
	replace race2 = 4 if race == "A"
	replace race2 = 5 if race == "N"
	replace race2 = 6 if race == "O"
	replace race2 = 7 if race == ""

* generate dummies ahead of collapsing on week/states
	gen unarmed = 1 if armed == "unarmed"
	gen nothreat = 1 if threat_level == "other"
	gen unarmed_nothreat = 1 if unarmed == 1 & nothreat == 1
	gen mental = 1 if signs_of_mental_illness == "True"
	gen black = 1 if race == "B"
	gen white = 1 if race == "W"
	gen hisp =  1 if race == "H"
	gen asian = 1 if race == "A"
	gen native = 1 if race == "N"
	gen orace = 1 if race == "O"
	gen undet = 1 if race == ""
	gen black_unarmed = 1 if unarmed == 1 & black == 1
	gen fois = 1

* calculate each year's YTD as June 30th (Day 181 for regular years, 182 for Leap Years)
	tabstat daily if daily <=182 & (year == 2020 | year == 2016), by(year) s(count)
	tabstat daily if daily <=181 & (year == 2015 | year == 2017 | year == 2018 | year == 2019), by(year) s(count)
	
	gen 	YTD = 465 if year == 2015
	replace YTD = 498 if year == 2016
	replace YTD = 493 if year == 2017
	replace YTD = 550 if year == 2018
	replace YTD = 484 if year == 2019
	replace YTD = 511 if year == 2020
	
	
* YEARLY LEVEL ANALYSES
preserve

	drop if oisdate >= 22097 // Cut off at June 30, 2020
	collapse (sum) fois black white hisp asian native orace undet unarmed unarmed_nothreat (first) YTD, by(year)

	* raw counts per year, overall
		graph bar YTD fois, over(year, relabel(6 "2020"))  ///
			title("Fatal Police Shootings per Year, 2015 - 2020", size(medsmall) span margin(0 0 3 0)) ///
			blabel(total, pos(inside) size(small) c(gs16)) ///
			ytitle("Total", size(small)) ///
			leg(pos(6) rows(1) size(small) label(1 "Through June 30th") label(2 "Year Total")) ///
			note("* {it:Data pulled 7/13/2020 from @washingtonpost: https://github.com/washingtonpost/data-police-shootings}", size(tiny) pos(7) span margin(0 0 0 3))
		
		graph export "fig 2.pdf", replace

	* raw counts, broken down by race
	* first, calculate %race for each year
		local varlist "black white hisp asian native orace undet"
		foreach i in `varlist' {
			gen p_`i' = (`i'/fois)*100
			}
		
		graph bar (sum) p_native p_black p_hisp p_white p_asian p_orace p_undet, over(year, relabel(6 "2020*")) ///
			title("Fatal Police Shootings per Year, 2015 - 2020" "By Race/Ethnicity", size(medsmall) span margin(0 0 3 0)) ///
			blabel(total, pos(outside) format(%4.0f) size(vsmall)) ///
			ytitle("Percent", size(small)) ///
			leg(pos(6) rows(2) size(vsmall) label(1 "Native American/Indigenous") label(2 "Black") label(3 "Latinx") label(4 "White") label(5 "Asian/Pacific Islander") label(6 "Other") label(7 "Undetermined")) ///
			note("* {it:As of 6/30/2020.}" ///
				"** {it:Data pulled 7/13/2020 from @washingtonpost: https://github.com/washingtonpost/data-police-shootings}", size(tiny) pos(7) span margin(0 0 0 3))

	
	* overall rate per million, per year
		gen 	pop = 321418821 if year == 2015 // ACS 5-year estimates from Table DP05
		replace pop = 323127515 if year == 2016 // ACS 5-year estimates from Table DP05
		replace pop = 325719178 if year == 2017 // ACS 5-year estimates from Table DP05
		replace pop = 327167439 if year == 2018 // ACS 5-year estimates from Table DP05
		replace pop = 330269000 if year == 2019 // Census Projection, see Table 1 at https://www.census.gov/data/tables/2017/demo/popproj/2017-summary-tables.html
		replace pop = 332639000 if year == 2020 // Census Projection, see Table 1 at https://www.census.gov/data/tables/2017/demo/popproj/2017-summary-tables.html
		
		gen fois_rate = (fois/pop)*1000000
		format fois_rate %4.2f

	* rate per million, per year, by race
		gen 	pop_black = 39597600 if year == 2015 // ACS 5-year estimates from Table DP05
		replace pop_black = 39717127 if year == 2016
		replace pop_black = 40129593 if year == 2017
		replace pop_black = 40305870 if year == 2018
		
		gen 	pop_white = 197534496 if year == 2015 // ACS 5-year estimates from Table DP05
		replace pop_white = 197479450 if year == 2016
		replace pop_white = 197285202 if year == 2017
		replace pop_white = 197033939 if year == 2018
		
		gen 	pop_hisp = 56496122 if year == 2015 // ACS 5-year estimates from Table DP05 (see Hispanic or Latino of any race)
		replace pop_hisp = 57398719 if year == 2016
		replace pop_hisp = 58846134 if year == 2017
		replace pop_hisp = 59763631 if year == 2018
		
		gen 	pop_asian = 17583969 if year == 2015 // ACS 5-year estimates from Table DP05 (Asian + Native Hawaiian or Pacific Islander)
		replace pop_asian = 17878868 if year == 2016
		replace pop_asian = 18546624 if year == 2017
		replace pop_asian = 18753458 if year == 2018
		
		gen 	pop_native = 2069645 if year == 2015 // ACS 5-year estimates from Table DP05
		replace pop_native = 2125635 if year == 2016
		replace pop_native = 2145162 if year == 2017
		replace pop_native = 2180266 if year == 2018
		
		gen 	pop_other = 699309 if year == 2015 // ACS 5-year estimates from Table DP05 (Some other race)
		replace pop_other = 758275 if year == 2016
		replace pop_other = 833898 if year == 2017
		replace pop_other = 826107 if year == 2018

	* impute 2019 populations using linear regression models
		local races "pop_black pop_white pop_hisp pop_asian pop_native pop_other"
		foreach i in `races' {
			reg `i' year
			predict `i'i
		}
		
	* calculate fOIS rates for each group, 2015-2019
		gen black_rate  = (black/pop_blacki)*1000000
		gen white_rate  = (white/pop_whitei)*1000000
		gen hisp_rate   = (hisp/pop_hispi)*1000000
		gen asian_rate  = (asian/pop_asiani)*1000000
		gen native_rate = (native/pop_nativei)*1000000
		gen orace_rate  = (orace/pop_otheri)*1000000
		
		format *_rate %4.1f
	
	* line graph showing overall rate and group rates, 2015-2019
		twoway connected fois_rate native_rate black_rate hisp_rate white_rate asian_rate year if year != 2020, ///
			title("Fatal Police Shootings per 1 Million Citizens, 2015 - 2019", size(medsmall)) ///
			lw(medthick thin thin thin thin thin) ///
			lp(solid shortdash shortdash shortdash shortdash shortdash) ///
			m(point point point point point point) ///
			mlabel(fois_rate native_rate black_rate hisp_rate white_rate asian_rate) ///
			mlabs(vsmall vsmall vsmall vsmall vsmall vsmall) ///
			mlabp(12 12 12 12 12 12) ///
			mlabc(gs0) lc(gs0) mlabg(3) ///
			ytitle("Rate per 1 Million", size(small)) ///
			xtitle("") ///
			leg(pos(6) size(vsmall) rows(2) label(1 "Overall") label(2 "Native American/Indigenous") label(3 "Black") label(4 "Latinx") label(5 "White") label(6 "Asian/Pacific Islander")) ///
			note("* {it:Data pulled 7/13/2020 from @washingtonpost: https://github.com/washingtonpost/data-police-shootings}", size(tiny) pos(7) span margin(0 0 0 3))
			
		graph export "fig 1.pdf", replace	

	* bar chart showing rates by race, by year	
		graph bar (sum) black_rate white_rate hisp_rate asian_rate native_rate if year !=2020, over(year) ///
			title("Fatal Police Shooting Rates per Year, 2015 - 2019" "By Race/Ethnicity", size(medsmall) span margin(0 0 3 0)) ///
			blabel(total, pos(outside) format(%4.2f) size(vsmall)) ///
			ytitle("Fatal Shootings per 1 Million", size(small)) ///
			leg(pos(6) rows(1) size(vsmall) label(1 "Black") label(2 "White") label(3 "Hispanic") label(4 "Asian") label(5 "Native American")) ///
			note("* {it:As of 6/30/2020.}" ///
				"** {it:Data pulled 7/13/2020 from @washingtonpost: https://github.com/washingtonpost/data-police-shootings}", size(tiny) pos(7) span margin(0 0 0 3))
	
restore


* WEEKLY LEVEL ANALYSES
preserve

	gen fois15 = 1 if year == 2015
	gen fois16 = 1 if year == 2016
	gen fois17 = 1 if year == 2017
	gen fois18 = 1 if year == 2018
	gen fois19 = 1 if year == 2019
	gen fois20 = 1 if year == 2020
	
	collapse (sum) unarmed nothreat unarmed_nothreat mental black white hisp asian native orace undet black_unarmed fois*, by(woy)
	
	egen avg_woy = rmean(fois15 fois16 fois17 fois18 fois19)
	
	sum fois20 avg_woy if woy <=27
	
	list woy fois20 avg_woy if woy >= 15 & woy <= 27 // George Floyd killed in Week #21
	
	* ois per week in 2020 v. previous daily minimums and maximums
		egen prevmin = rowmin(fois15 fois16 fois17 fois18 fois19)
		egen prevmax = rowmax(fois15 fois16 fois17 fois18 fois19)

		line prevmin woy, lc(gs6) lp(dot) ///
			|| line prevmax woy, lc(gs11) lp(shortdash) ///
			|| line fois20 woy if woy <= 27, lc(blue) lw(medthick) ///
			leg(order(1 2 3) pos(6) rows(1) label(1 "2015-19 Minimum") label(2 "2015-19 Maximum") label(3 "2020")) xlab(,labs(small)) ///
			title("Fatal OIS Per Week, 2015 - 2020*", size(small)) ///
			yla(0(5)35) xline(9, lc(gs0)) text(31 14.5 "US reports 1st COVID-19 death", size(vsmall) c(gs0)) ///
			xline(21, lc(gs0)) text(6 28.1 "George Floyd killed by Minneapolis police", size(vsmall) c(gs0)) ///
			xla(1(1)52, labs(tiny) nogrid) xtitle("Week of Year", size(small) margin(top)) ///
			note("* {it:Data pulled 7/13/2020 from @washingtonpost: https://github.com/washingtonpost/data-police-shootings}", size(tiny) pos(7) span margin(0 0 0 3))

			graph export "fig 3.pdf", replace
			
		line prevmin woy, lc(gs12) ///
			|| line prevmax woy, lc(gs12) ///
			|| line avg_woy woy, lc(gs3) lp(dot) ///
			|| line fois20 woy if woy <= 27, lc(blue) lw(medthick) ///
			leg(order(1 3 4) pos(6) rows(1) label(1 "2015-19 Min/Max") label(3 "2015-19 Average") label(4 "2020")) xlab(,labs(small)) ///
			title("Fatal OIS Per Week, 2015 - 2020*", size(small)) ///
			yla(0(5)35) xline(9, lc(gs0)) text(31 14.5 "US reports 1st COVID-19 death", size(vsmall) c(gs0)) ///
			xline(21, lc(gs0)) text(6 28.1 "George Floyd killed by Minneapolis police", size(vsmall) c(gs0)) ///
			xla(1(1)52, labs(tiny) nogrid) xtitle("Week of Year", size(small) margin(top)) ///
			note("* {it:Data pulled 7/13/2020 from @washingtonpost: https://github.com/washingtonpost/data-police-shootings}", size(tiny) pos(7) span margin(0 0 0 3))
			
			graph export "fig 3b.pdf", replace
			
restore


* STATE LEVEL ANALYSES
preserve

	drop if oisdate >= 22097 // Cut off at June 30, 2020 for Year End comparisons
 
	gen fois15 = 1 if year == 2015
	gen fois16 = 1 if year == 2016
	gen fois17 = 1 if year == 2017
	gen fois18 = 1 if year == 2018
	gen fois19 = 1 if year == 2019
	gen fois20 = 1 if year == 2020

	
	collapse (sum) unarmed nothreat unarmed_nothreat mental black white hisp asian native orace undet black_unarmed fois*, by(state)
	
	* table showing state counts per year
		gsort state
		
		* merge annual state populations to create a rate per 1 million citizens
			merge 1:1 state using "~\state population data.dta"

		* create annual rates
			gen rate2015 = (fois15/pop2015)*1000000
			gen rate2016 = (fois16/pop2016)*1000000
			gen rate2017 = (fois17/pop2017)*1000000
			gen rate2018 = (fois18/pop2018)*1000000
			gen rate2019 = (fois19/pop2019)*1000000
			
		* create 2020 rates
			gen rate2020 = (fois20/pop2019)*1000000
			format rate* %4.2f
			
			list state fois15 rate2015 fois16 rate2016 fois17 rate2017 fois18 rate2018 fois19 rate2019 fois20 rate2020, sep(51)
	
restore

preserve
	
	drop if month >= 7 // Cut off at June 30 for YTD comparisons
	
	gen fois15 = 1 if year == 2015
	gen fois16 = 1 if year == 2016
	gen fois17 = 1 if year == 2017
	gen fois18 = 1 if year == 2018
	gen fois19 = 1 if year == 2019
	gen fois20 = 1 if year == 2020

	
	collapse (sum) unarmed nothreat unarmed_nothreat mental black white hisp asian native orace undet black_unarmed fois*, by(state)
	
	* table showing YTD state counts and rates per year as of June 30
	
		* merge annual state populations to create a rate per 1 million citizens
			merge 1:1 state using "~\state population data.dta"

		* create annual rates
			gen rate2015 = (fois15/pop2015)*1000000
			gen rate2016 = (fois16/pop2016)*1000000
			gen rate2017 = (fois17/pop2017)*1000000
			gen rate2018 = (fois18/pop2018)*1000000
			gen rate2019 = (fois19/pop2019)*1000000
			
		* create 2020 rates
			gen rate2020 = (fois20/pop2019)*1000000
			format rate* %4.2f
			
			list state fois15 rate2015 fois16 rate2016 fois17 rate2017 fois18 rate2018 fois19 rate2019 fois20 rate2020, sep(51)
	
restore

preserve
	
	drop if month >= 7 // Cut off at June 30, 2020
 
	gen fois15 = 1 if year == 2015
	gen fois16 = 1 if year == 2016
	gen fois17 = 1 if year == 2017
	gen fois18 = 1 if year == 2018
	gen fois19 = 1 if year == 2019
	gen fois20 = 1 if year == 2020

	collapse (sum) unarmed nothreat unarmed_nothreat mental black white hisp asian native orace undet black_unarmed fois*, by(state)
	
	* merge annual state populations to create a rate per 1 million citizens
		merge 1:1 state using "~\state population data.dta"

	* create annual rates
		gen rate2015 = (fois15/pop2015)*1000000
		gen rate2016 = (fois16/pop2016)*1000000
		gen rate2017 = (fois17/pop2017)*1000000
		gen rate2018 = (fois18/pop2018)*1000000
		gen rate2019 = (fois19/pop2019)*1000000
	
	* create 5-year average rate
		egen avgrate = rmean(rate*)
		sum avgrate // mean = 1.8, sd = 1.0, range = .4 - 4.9
	
	* map 5-year average rates per million
		maptile avgrate, geo(state) cutv(0 .99 1.99 2.99 3.99) ///
			fc(YlOrBr) ///
			twopt(title("2015 - 2019*", size(medsmall)) ///
			legend(off) ///
			name(mapA, replace))
		
	* create 2020 rates
		gen rate2020 = (fois20/pop2019)*1000000
		format rate* %4.2f
				
		maptile rate2020, geo(state) cutv(0 .99 1.99 2.99 3.99) ///
			fc(YlOrBr) ///
			twopt(title("2020", size(medsmall)) ///
			legend(size(vsmall) order(2 3 4 5 6 7) title("Fatal shootings" "per 1 million residents", size(vsmall)) ///
				label(2 "0.0") label(3 "0.1 - 0.9") label(4 "1.0 - 1.9") label(5 "2.0 - 2.9") ///
				label(6 "3.0 - 3.9") label(7 "> 4.0")) ///
			name(mapB, replace))
		
	* combine graphs
		graph combine mapA mapB, title("Fatal Police Shooting Rates through June 30th", size(medsmall)) ///
		note("* {it: 5-Year average rate through June 30th (2015-19)}", size(tiny) pos(7) span margin(1 0 1 3))
		
		graph export "fig 4.pdf", replace
	
	gsort -rate2020 state
	list state rate2020 avgrate
	
	* take a closer look at states that saw movement in 2020 relative to previous years
		egen avgcount = rmean(fois15 fois16 fois17 fois18 fois19)
		
		gsort state
		list state avgcount avgrate fois20 rate2020 if ///
			state == "CO" | state == "CT" | state == "FL" | state == "IL" | state == "MI" | ///
			state == "MT" | state == "NV" | state == "TX" | state == "WV" 

