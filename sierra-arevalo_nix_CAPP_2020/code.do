/***************************************************************
- Sierra-Arevalo & Nix (2020)
- "Gun Victimization in the Line of Duty: Fatal and Non-fatal firearm assaults on police officers in the United States, 2014-2019"
- Criminology & Public Policy, 19(3), pp. TBD
- Code written 12/12/19
- Last updated 3/17/2020
***************************************************************/
 
* Set working directory to save tables/figures
	cd "$\Figures"  

* Call up the data
	use "$\gva_incidents.dta", replace
	
* Tally up the ToRemove cases
	tab ToRemove // Remove 510 of 1977 cases, Analytic N = 1467

* build table summarizing why cases were excluded (Appendix A)
	tab agencytype if notactiveswornlocalstate == 1, sort
	gen FED = regexm(agencytype, "Federal") == 1
	tab FED // n = 60
	
	tab rank if notactiveswornlocalstate == 1 & FED != 1, sort
	
	tab offduty, sort
	gen RETIRED = regexm(rank, "Retire") == 1
	tab RETIRED
	
	tab type_new if ToRemove == 1, sort
	gen ACCIDENT = regexm(type_new, "Accident") == 1
		replace ACCIDENT = 1 if regexm(type_new, "accident") == 1
	tab ACCIDENT
	
	gen BLUE = regexm(type_new, "blue") == 1
	tab BLUE ToRemove // 1 BlueOnBlue gets retained b/c suspect inflicted several nonfatal gunshot wounds.
	
	gen SELF = regexm(type_new, "Self") == 1
		replace SELF = 1 if regexm(type_new, "self") == 1
		replace SELF = 1 if regexm(type_new, "Suicide") == 1
		replace SELF = 1 if regexm(type_new, "suicide") == 1
	tab SELF
	
	gen SUICIDE = regexm(type_new, "Suicide") == 1
	tab SUICIDE
	
	gen LIED = regexm(type_new, "lied") == 1
		replace LIED = 1 if regexm(type_new, "criminal activity") == 1
	tab LIED

* Create binary variables for fatals, nonfatals, and total
	gen fatal = .
	replace fatal = 1 if Status == "Killed"
	replace fatal = 0 if Status == "Injured" | Status == "Injured,Arrested"
	label define fatall 0 "Non-fatal" 1 "Fatal" 
	label values fatal fatall
	tab fatal
	tab fatal if ToRemove != 1  // N = 1,467

	gen nonfatal = .
	replace nonfatal = 1 if fatal == 0
	replace nonfatal = 0 if fatal == 1

	gen total = fatal+nonfatal

* extract year and month from Date variable
	gen year = year(Date)
	gen month = month(Date)
	
* collapse on incident to determine how many incidents officers were nested in
	preserve
		drop if ToRemove == 1
		collapse (mean) year (sum) fatal nonfatal total, by(IncidentID)
		tab year // 1185 incidents involving 1467 officers
	restore
	

* calculate monthly means for discussion of Figure 1
	tab month if ToRemove != 1, sort 
	egen month_total = total(total) if ToRemove !=1, by(month)
	gen month_mean = month_total/6
	tab month month_mean


/***** TABLE 1: Fatal and nonfatal shootings by year *****/
	tab year fatal if ToRemove != 1, row chi

****************************************************
/***** FIGURE 1: Monthly Assaults, Nationwide *****/
****************************************************

* first, generate a "month+year" variable
	gen moyear =  ym(year, month)
	format moyear %tm
	tab moyear if ToRemove != 1

* collapse on moyear to plot line graphs for Fig 1
	preserve

		drop if ToRemove == 1

		collapse (sum) fatal nonfatal total, by (moyear)

		sum moyear // jan2014 = 648; dec2019 = 719
	   
		twoway connected fatal nonfatal total moyear, ytitle("Firearm Assaults") xtitle("") ///
			legend(pos(6) rows(2) size(small) label(1 Fatal) label(2 Nonfatal) label(3 Total)) ///
			ylabel(,format(%4.0f)) m(point point point) ///
			xlabel(648(3)720, format(%tmMon_YY) angle(45) labs(vsmall)) ///
			lc(plr1 plb1 gs0) ///
			|| lfit fatal moyear, lc(plr1) lp(shortdash) ///
			|| lfit nonfatal moyear, lc(plb1) lp(shortdash) ///
			|| lfit total moyear, lc(gs0) lp(shortdash)
				  
		graph export "$\fig1.pdf", replace
		  
	restore


/* state-level analysis looking at variation in raw totals and rates per 10K sworn
   first, collapse the data to state level
   to do that, will need to encode the "State" variable
   then, drop if "ToRemove == 1"
   then, create binary indicators for each year so we can generate yearly totals for each state post-collapse */

	encode(State), gen(state) label(State)

	**********
	preserve

		drop if ToRemove == 1

		gen t14 = 1 if year == 2014
		gen t15 = 1 if year == 2015
		gen t16 = 1 if year == 2016
		gen t17 = 1 if year == 2017
		gen t18 = 1 if year == 2018
		gen t19 = 1 if year == 2019

		gen f14 = 1 if year == 2014 & fatal == 1
		gen f15 = 1 if year == 2015 & fatal == 1
		gen f16 = 1 if year == 2016 & fatal == 1
		gen f17 = 1 if year == 2017 & fatal == 1
		gen f18 = 1 if year == 2018 & fatal == 1
		gen f19 = 1 if year == 2019 & fatal == 1

		gen nf14 = 1 if year == 2014 & fatal == 0
		gen nf15 = 1 if year == 2015 & fatal == 0
		gen nf16 = 1 if year == 2016 & fatal == 0
		gen nf17 = 1 if year == 2017 & fatal == 0
		gen nf18 = 1 if year == 2018 & fatal == 0
		gen nf19 = 1 if year == 2019 & fatal == 0


		collapse (sum) t1* f1* nf1*, by(state)

	/* merge police employee data
	   estimates from UCR Table 77, 2013 to 2018; 2019 imputed
	   Alaska reported only 5 officers in 2015; this year imputed using same process
	   WV didn't report data in 2014; this year imputed using same process */

		gsort state
		gen ID = _n
		merge 1:1 ID using "$\police employee data 2013-19.dta"
		list state State_full State_postal // check that everything lines up
		drop State_full
		rename state State_full
		rename State_postal state
	   
		**************************************************************************
		/***** FIGURE 3: Bar chart showing # of assaults per state, 2014-19 *****/
		**************************************************************************	
			egen total = rsum(t1*)
			
			* confirm N = 1467
				tabstat total, by(state) s(sum)
				
			sum total // M = 28.765, SD = 28.389
				
			graph hbar (asis) total, over(state, lab(labs(tiny)) sort(1) descending) scheme(plottig) ///
				yline (28.77) text(36 40 "Mean=28.77", size(vsmall) c(red)) ///
				bar(1, c(gs16) lw(vvthin) lc(gs0)) ytitle("Total Firearm Assaults" "(6-Year Sum)") blabel(total, pos(outside))
			
			graph export "$\fig3.pdf", replace
			
		***************************************************************************
		/* SUPPLEMENT TO F3: Bar chart showing # of assaults per state, per year */
		***************************************************************************
			graph hbar (asis) t14, over(state, lab(labs(tiny)) sort(1) descending) scheme(plottig) ///
				bar(1, c(plb1) lw(vvthin) lc(gs0)) ytitle("") blabel(total, pos(outside)) name(state14, replace)
			graph hbar (asis) t15, over(state, lab(labs(tiny)) sort(1) descending) scheme(plottig) ///
				bar(1, c(plb1) lw(vvthin) lc(gs0)) ytitle("") blabel(total, pos(outside)) name(state15, replace)
			graph hbar (asis) t16, over(state, lab(labs(tiny)) sort(1) descending) scheme(plottig) ///
				bar(1, c(plb1) lw(vvthin) lc(gs0)) ytitle("") blabel(total, pos(outside)) name(state16, replace)
			graph hbar (asis) t17, over(state, lab(labs(tiny)) sort(1) descending) scheme(plottig) ///
				bar(1, c(plb1) lw(vvthin) lc(gs0)) ytitle("") blabel(total, pos(outside)) name(state17, replace)
			graph hbar (asis) t18, over(state, lab(labs(tiny)) sort(1) descending) scheme(plottig) ///
				bar(1, c(plb1) lw(vvthin) lc(gs0)) ytitle("") blabel(total, pos(outside)) name(state18, replace)
			graph hbar (asis) t19, over(state, lab(labs(tiny)) sort(1) descending) scheme(plottig) ///
				bar(1, c(plb1) lw(vvthin) lc(gs0)) ytitle("") blabel(total, pos(outside)) name(state19, replace)

			graph combine state14 state15 state16 state17 state18 state19, rows(2) altshrink
			graph export "$\fig3_sup.pdf"
			
			
		egen avgsworn = rmean(sworn*)
		format avgsworn %4.0f // round average to nearest whole number
		list state avgsworn

		* now, create yearly rates of fatal AND nonfatal shootings per 1000 sworn
			gen tr14 = (t14/sworn14)*1000
			gen tr15 = (t15/sworn15)*1000
			gen tr16 = (t16/sworn16)*1000
			gen tr17 = (t17/sworn17)*1000
			gen tr18 = (t18/sworn18)*1000
			gen tr19 = (t19/sworn19)*1000

		* fatal shootings ONLY per 1000 sworn
			gen fr14 = (f14/sworn14)*1000
			gen fr15 = (f15/sworn15)*1000
			gen fr16 = (f16/sworn16)*1000
			gen fr17 = (f17/sworn17)*1000
			gen fr18 = (f18/sworn18)*1000
			gen fr19 = (f19/sworn19)*1000

		* nonfatal shootings ONLY per 1000 sworn
			gen nfr14 = (nf14/sworn14)*1000
			gen nfr15 = (nf15/sworn15)*1000
			gen nfr16 = (nf16/sworn16)*1000
			gen nfr17 = (nf17/sworn17)*1000
			gen nfr18 = (nf18/sworn18)*1000
			gen nfr19 = (nf19/sworn19)*1000

		* create average rate over this period
			egen avg_overall = rmean(tr*)

		* look at the data
			format tr* fr* nfr* avg_overall %4.3f
			gsort -avg_overall state
			list state avg_overall tr*, table
	   
		**************************************************************************
		/***** FIGURE 4: Heatmap showing 6-year avg. assault rate per state *****/
		**************************************************************************
	   
			sum avg_overall
			// mean = .4689, sd = .3757
			// cut values at -1 SD, -.5 SD, Mean, .5 SD, 1 SD, 1.5 SD, 2 SD
			di .4689 - (.3757 * 2.0)
			di .4689 - (.3757 * 1.5)
			di .4689 - (.3757 * 1.0)
			di .4689 - (.3757 * 0.5)
			di .4689 + (.3757 * 0.5)
			di .4689 + (.3757 * 1.0)
			di .4689 + (.3757 * 1.5)
			di .4689 + (.3757 * 2.0)
			
			maptile avg_overall, geo(state) cutv(.093 .281 .469 .657 .845 1.032 1.220) ///
				fc(YlOrRd) ///
				twopt(legend(size(small))) ///
				savegraph("$\fig4.pdf") replace
				   
		***************************************************************	   
		/***** FIGURE 5: Bar chart showing precise assault rates *****/
		***************************************************************
			graph hbar (asis) avg_overall, over(state, lab(labs(tiny)) sort(1) descending) scheme(plottig) ///
				yline(.4689) text(.57 55 "Mean=0.47", size(vsmall) c(red)) ///
				bar(1, c(plb1) lw(vvthin) lc(gs0)) ///
				ytitle("Firearm Assault Rate" "(6-Year Average)") blabel(total, pos(outside) format(%4.2f)) name(officers, replace)

			graph export "$\fig5.pdf", replace
		   
		************************************************************************************************************
		/***** FOR APPENDIX: Show results if we used presumably more reliable denominators for IN, MS, and WV 
			  see "Alternate Estimates for IN MS WV" word document in Dropbox *****/
		************************************************************************************************************
			replace avg_overall = .393 if state == "IN"
			replace avg_overall = .800 if state == "MS"
			replace avg_overall = .542 if state == "WV"

			sum avg_overall // M = .4318, SD = .2726
			// cut values at -1 SD, -.5 SD, Mean, .5 SD, 1 SD, 1.5 SD, 2 SD
			di .4318 - (.2726 * 2.0)
			di .4318 - (.2726 * 1.5)
			di .4318 - (.2726 * 1.0)
			di .4318 - (.2726 * 0.5)
			di .4318 + (.2726 * 0.5)
			di .4318 + (.2726 * 1.0)
			di .4318 + (.2726 * 1.5)
			di .4318 + (.2726 * 2.0)
		   
			graph hbar (asis) avg_overall, over(state, lab(labs(tiny)) sort(1) descending) scheme(plottig) ///
				yline(.4318) text(.49 45 "Mean=0.43", size(vsmall) c(red)) ///
				bar(1, c(plb1) lw(vvthin) lc(gs0)) ///
				ytitle("Firearm Assault Rate" "(6-Year Average)") blabel(total, pos(outside) format(%4.2f)) 

			graph export "$\appD.pdf", replace
			

	***************************************************
	/*** FIGURE 2: National rates, 2014/15 to 2019 ***/
	***************************************************

		* clear data and create new dataset with columns for year and nat'l rates
		   
			tabstat sworn*, s(sum) // displays US sworn total by year
			tabstat t1*, s(sum) // total shootings per year
			tabstat f1*, s(sum) // total fatal shootings per year
			tabstat nf1*, s(sum) // total non-fatal shootings per year
		   
		* use these figures to generate the rates in the nat'l dataset 
		   
			clear
			set obs 6

			gen year = .
			replace year = 2014 in 1
			replace year = 2015 in 2
			replace year = 2016 in 3
			replace year = 2017 in 4
			replace year = 2018 in 5
			replace year = 2019 in 6

			gen overall = .
			replace overall = (189/631621)*100000 if year == 2014
			replace overall = (234/637003)*100000 if year == 2015
			replace overall = (288/652936)*100000 if year == 2016
			replace overall = (248/670279)*100000 if year == 2017
			replace overall = (240/686665)*100000 if year == 2018
			replace overall = (268/711690)*100000 if year == 2019
			label variable overall "Total"

			gen fatal= .
			replace fatal = (37/631621)*100000  if year == 2014
			replace fatal = (32/637003)*100000  if year == 2015
			replace fatal = (59/652936)*100000  if year == 2016
			replace fatal = (37/670279)*100000  if year == 2017
			replace fatal = (45/686665)*100000  if year == 2018
			replace fatal = (39/711690)*100000  if year == 2019
			label variable fatal "Fatal"

			gen nonfatal= .
			replace nonfatal = (152/631621)*100000  if year == 2014
			replace nonfatal = (202/637003)*100000  if year == 2015
			replace nonfatal = (229/652936)*100000  if year == 2016
			replace nonfatal = (211/670279)*100000  if year == 2017
			replace nonfatal = (195/686665)*100000  if year == 2018
			replace nonfatal = (229/711690)*100000  if year == 2019
			label variable nonfatal "Nonfatal"

			format overall fatal nonfatal %4.2f

				  
			twoway connected fatal nonfatal overall year, ///
				ytitle("Firearm Assaults per 100K Officers") xtitle("") legend(pos(6) rows(2) size(small)) ///
				ylabel(,format(%4.0f)) ///
				m(point point point) mlabel(fatal nonfatal overall) mlabs(vsmall vsmall vsmall) mlabp(6 6 6) ///
				mlabc(plr1 plb1 gs0) lc(plr1 plb1 gs0) ///
				|| lfit fatal year, lc(plr1) lp(shortdash) text(7 2018.5 "y= -0.025x + 6.336", size(tiny) c(plr1)) ///
				|| lfit nonfatal year, lc(plb1) lp(shortdash) text(33 2018.5 "y= 0.772x + 27.782", size(tiny) c(plb1)) ///
				|| lfit overall year, lc(gs0) lp(shortdash) text(39 2018.5 "y= 0.750x + 34.103", size(tiny))

			graph export "$\fig2.pdf", replace
		   		   
		* look how the fitted line changes with 2015 as start point
			drop if year == 2014
	   
			twoway connected fatal nonfatal overall year, ///
				ytitle("Firearm Assaults per 100K Officers") xtitle("") legend(pos(6) rows(2) size(small)) ///
				ylabel(,format(%4.0f)) ///
				m(point point point) mlabel(fatal nonfatal overall) mlabs(vsmall vsmall vsmall) mlabp(6 6 6) ///
				mlabc(plr1 plb1 gs0) lc(plr1 plb1 gs0) ///
				|| lfit fatal year, lc(plr1) lp(shortdash) text(7 2018.5 "y= -0.160x + 6.808", size(tiny) c(plr1)) ///
				|| lfit nonfatal year, lc(plb1) lp(shortdash) text(32 2018.5 "y= -0.573x + 33.487", size(tiny) c(plb1)) ///
				|| lfit overall year, lc(gs0) lp(shortdash) text(38 2018.5 "y= -0.730x + 40.280", size(tiny))
					  
			graph export "$\appE.pdf", replace
			   
	restore
