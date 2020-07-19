*********************************************************
/*               STUDY 1: lower bound                  */
*********************************************************

/* Simulate 1000x what would happen if we assumed nonrespondents were 1-2 SDs LOWER on our DV than the mean
   among respondents (i.e., lower bound) */
   
/* first, this program pulls up the study 1 data and adds 1,206 blank cases (for 1,206 nonrespondents)
   then, it flags the nonrespondents with a dummy
   then, it generates a new DV, "aud_lower" that assumes all nonrespondents would have scored 1-2 SDs below our observed mean on the DV
   so respondents get their observed value, nonrespondents get a random score 1-2 SDs below the observed mean
   then, using MI, it imputes the other missing values based on this new DV */

clear
program drop boogeyman1l
   
program define boogeyman1l
	drop _all
	use "~\study1_data_for_simulation.dta"
	set obs `=_N+1206'
	gen nonrespond = .
	replace nonrespond = 1 if RespondentID == .
	replace nonrespond = 0 if RespondentID != .
	gen aud_lower = 2.7019084 - runiform(0,.7791836) if nonrespond == 1
	replace aud_lower = aud if nonrespond == 0
	replace aud_lower = 2.7019084 - runiform(0,.7791836) if aud == . & nonrespond == 0
	mi set mlong
	mi register impute aud_lower mistreat animus pcrime Male White BachDegree CJYears sup com
	mi impute mvn aud_lower mistreat animus pcrime Male White BachDegree CJYears sup com, add(25)
	mi estimate, post: regress aud_lower mistreat animus pcrime Male White BachDegree CJYears sup com, robust
end

simulate _b _se e(F_mi) e(p_mi), reps(1000) seed(112317): boogeyman1l
beep

sum _b*
sum _se*
sum _eq2* // F-stats and model p-values


/* calculate t tests for each of the independent variables to see how many times out of 1000 they're significant */
gen tt_mistreat = _b_mistreat/_se_mistreat
gen tt_animus = _b_animus/_se_animus
gen tt_pcrime = _b_pcrime/_se_pcrime

sum tt_mistreat
sum tt_animus
sum tt_pcrime



clear

*********************************************************
/*               STUDY 1: upper bound                  */
*********************************************************

/* Simulate 1000x what would happen if we assumed nonrespondents were 1-2 SDs HIGHER on our DV than the mean
   among respondents (i.e., upper bound) */
   
/* first, this program pulls up the study 1 data and adds 1,206 blank cases (for 1,206 nonrespondents)
   then, it flags the nonrespondents with a dummy
   then, it generates a new DV, "aud_upper" that assumes all nonrespondents would have scored 1-2 SDs above our observed mean on the DV
   so respondents get their observed value, nonrespondents get a random score 1-2 SDs above the observed mean
   then, using MI, it imputes the other missing values based on this new DV */

program define boogeyman1u
	drop _all
	use "~\study1_data_for_simulation.dta"
	set obs `=_N+1206'
	gen nonrespond = .
	replace nonrespond = 1 if RespondentID == .
	replace nonrespond = 0 if RespondentID != .
    gen aud_upper = 4.2602756 + runiform(0,.7791836) if nonrespond == 1
    replace aud_upper = aud if nonrespond == 0
    replace aud_upper = 4.2602756 + runiform(0,.7791836) if aud == . & nonrespond == 0
    replace aud_upper = 5 if aud_upper > 5 // 64 values > 5 for some reason?
    sum aud aud_upper
	mi set mlong
	mi register impute aud_upper mistreat animus pcrime Male White BachDegree CJYears sup com
	mi impute mvn aud_upper mistreat animus pcrime Male White BachDegree CJYears sup com, add(25)
	mi estimate, post: regress aud_upper mistreat animus pcrime Male White BachDegree CJYears sup com, robust
end

simulate _b _se e(F_mi) e(p_mi), reps(1000) seed(112317): boogeyman1u
beep

sum _b*
sum _se*
sum _eq2* // F-statistics and model p-values


/* calculate t tests for each of the independent variables to see how many times out of 1000 they're significant */
gen tt_mistreat = _b_mistreat/_se_mistreat
gen tt_animus = _b_animus/_se_animus
gen tt_pcrime = _b_pcrime/_se_pcrime

sum tt_mistreat
sum tt_animus
sum tt_pcrime

sum tt_mistreat if tt_mistreat <= -1.96
sum tt_pcrime if tt_pcrime <= -1.96



clear

*********************************************************
/*               STUDY 2: lower bound                  */
*********************************************************

/* Simulate 1000x what would happen if we assumed nonrespondents were 1-2 SDs LOWER on our DV than the mean
   among respondents (i.e., lower bound) */
   
/* we know we are missing the following Ns for each stratum:
   - 0  to 24: 624 - 149 = 475
   - 24 to 49: 624 - 172 = 452
   - 50 to 99: 624 - 168 = 456 
   - >= 100:   624 - 176 = 448
   
   note there are also 8 respondents for whom we don't know which stratum they belong (item-missing)
   so, we'll want to randomly assign this many nonrespondents to each stratum for each simulation, and
   we're treating the 8 respondents with unknown strata as nonrespondents for the purposes of simulating */

program define boogeyman2l
    drop _all
    use "~\study2_data_for_simulation.dta"
	drop if sworn == . // drop the 8 respondents we can't place into a stratum
	set obs `=_N+1831'
	replace sworn = 1 in 666/1140 // n = 475
	replace sworn = 2 in 1141/1592 // n = 452
	replace sworn = 3 in 1593/2048 // n = 456
	replace sworn = 4 in 2049/2496 // n = 448
    gen nonrespond = .
    replace nonrespond = 1 if id == .
    replace nonrespond = 0 if id != .
    gen aud_lower = 3.4773234 - runiform(0,.4431316) if nonrespond == 1
    replace aud_lower = aud if nonrespond == 0
    replace aud_lower = 3.4773234 - runiform(0,.4431316) if aud == . & nonrespond == 0
	drop sworn2 fweight
	gen sworn2 = .
	replace sworn2 = 1 if sworn == 4
	replace sworn2 = 0 if sworn <= 3
	gen fweight = .
	replace fweight = 3.3137 if sworn == 1
	replace fweight = 0.5174 if sworn == 2
	replace fweight = 0.2743 if sworn == 3
	replace fweight = 0.2051 if sworn == 4
    mi set mlong
    mi register impute aud_lower animus ln_avgvcrate ln_pblack ln_blackgrowth ln_phisp ///
                ln_hispgrowth lmedia nmedia chief LEyrs masters sworn2 whitemale ///
                ne mw we ln_pop2016 ln_unemployment PercentTrump
    mi impute mvn aud_lower animus ln_avgvcrate ln_pblack ln_blackgrowth ln_phisp ///
              ln_hispgrowth lmedia nmedia chief LEyrs masters sworn2 whitemale ///
              ne mw we ln_pop2016 ln_unemployment PercentTrump, add(25)
    mi estimate, post: regress aud_lower animus lmedia nmedia ln_avgvcrate ln_pblack ln_phisp ln_blackgrowth ///
                       ln_hispgrowth chief LEyrs masters sworn2 whitemale ///
                       ne mw we ln_pop2016 ln_unemployment PercentTrump [pweight=fweight], robust
end

simulate _b _se e(F_mi) e(p_mi), reps(1000) seed(112317): boogeyman2l
beep

sum _b*
sum _se*
sum _eq2* // F-statistics and model p-values

gen tt_animus = _b_animus/_se_animus
gen tt_lmedia = _b_lmedia/_se_lmedia
gen tt_nmedia = _b_nmedia/_se_nmedia
gen tt_crime = _b_ln_avgvcrate/_se_ln_avgvcrate
gen tt_black = _b_ln_pblack/_se_ln_pblack
gen tt_hisp = _b_ln_phisp/_se_ln_phisp
gen tt_blackgrowth = _b_ln_blackgrowth/_se_ln_blackgrowth
gen tt_hispgrowth = _b_ln_hispgrowth/_se_ln_hispgrowth

sum tt_*



clear

*********************************************************
/*               STUDY 2: upper bound                  */
*********************************************************

/* Simulate 1000x what would happen if we assumed nonrespondents were 1-2 SDs HIGHER on our DV than the mean
   among respondents (i.e., lower bound) */
   
/* we know we are missing the following Ns for each stratum:
   - 0  to 24: 624 - 149 = 475
   - 24 to 49: 624 - 172 = 452
   - 50 to 99: 624 - 168 = 456 
   - >= 100:   624 - 176 = 448
   
   note there are also 8 respondents for whom we don't know which stratum they belong (item-missing)
   so, we'll want to randomly assign this many nonrespondents to each stratum for each simulation, and
   we're treating the 8 respondents with unknown strata as nonrespondents for the purposes of simulating */

program define boogeyman2u
    drop _all
    use "~\study2_data_for_simulation.dta"
	drop if sworn == . // drop the 8 respondents we can't place into a stratum (this is what we did in OS)
	set obs `=_N+1831'
	replace sworn = 1 in 666/1140 // n = 475
	replace sworn = 2 in 1141/1592 // n = 452
	replace sworn = 3 in 1593/2048 // n = 456
	replace sworn = 4 in 2049/2496 // n = 448
    gen nonrespond = .
    replace nonrespond = 1 if id == .
    replace nonrespond = 0 if id != .
    gen aud_upper = 4.3635866 + runiform(0,.4431316) if nonrespond == 1
    replace aud_upper = aud if nonrespond == 0
    replace aud_upper = 4.3635866 + runiform(0,.4431316) if aud == . & nonrespond == 0
	drop sworn2 fweight
	gen sworn2 = .
	replace sworn2 = 1 if sworn == 4
	replace sworn2 = 0 if sworn <= 3
	gen fweight = .
	replace fweight = 3.3137 if sworn == 1
	replace fweight = 0.5174 if sworn == 2
	replace fweight = 0.2743 if sworn == 3
	replace fweight = 0.2051 if sworn == 4
    mi set mlong
    mi register impute aud_upper animus ln_avgvcrate ln_pblack ln_blackgrowth ln_phisp ///
                ln_hispgrowth lmedia nmedia chief LEyrs masters sworn2 whitemale ///
                ne mw we ln_pop2016 ln_unemployment PercentTrump
    mi impute mvn aud_upper animus ln_avgvcrate ln_pblack ln_blackgrowth ln_phisp ///
              ln_hispgrowth lmedia nmedia chief LEyrs masters sworn2 whitemale ///
              ne mw we ln_pop2016 ln_unemployment PercentTrump, add(25)
    mi estimate, post: regress aud_upper animus lmedia nmedia ln_avgvcrate ln_pblack ln_phisp ln_blackgrowth ///
                       ln_hispgrowth chief LEyrs masters sworn2 whitemale ///
                       ne mw we ln_pop2016 ln_unemployment PercentTrump [pweight=fweight], robust
end

simulate _b _se e(F_mi), reps(1000) seed(112317): boogeyman2u
beep

sum _b*
sum _se*
sum _eq2* // F-statistics and model p-values

gen tt_animus = _b_animus/_se_animus
gen tt_lmedia = _b_lmedia/_se_lmedia
gen tt_nmedia = _b_nmedia/_se_nmedia
gen tt_crime = _b_ln_avgvcrate/_se_ln_avgvcrate
gen tt_black = _b_ln_pblack/_se_ln_pblack
gen tt_hisp = _b_ln_phisp/_se_ln_phisp
gen tt_blackgrowth = _b_ln_blackgrowth/_se_ln_blackgrowth
gen tt_hispgrowth = _b_ln_hispgrowth/_se_ln_hispgrowth

sum tt_*

