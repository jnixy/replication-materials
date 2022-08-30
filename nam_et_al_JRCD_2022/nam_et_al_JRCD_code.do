* Code for Nam et al., "Does procedural justice reduce the harmful effects of perceived ineffectiveness on police legitimacy?"
* Study 1 = Neighborhood survey fielded in 2013
* Study 2 = Qualtrics survey fielded Apr. 25 2022 - May 5 2022
	* Quotas for race (white/black), gender (male/female), and age (18-34, 35-54, 55+)
* Code written 5/5/22 by JN
* Last updated 6/27/22 by JN, SW, YN

********************************************************************************
********************************************************************************

version 17

* Study 1

* Set working directory & start a log
cd "" // insert filepath to the folder you saved the data in
log using "output_study1", replace

* Call up the data
use "data_study1.dta", clear

* GENERATE VARIABLES FOR ANALYSIS
* Recode "missing" to .
recode * (-99 = .)

* Dependent variable: Police legitimacy
factor Q6accept Q6disagree Q6trust, mine(1)
alpha Q6accept Q6disagree Q6trust
egen legit = rmean(Q6accept Q6disagree Q6trust)

* Independent variables
	*Procedural justice
	factor Q6respect Q6listen Q6fair Q6explain, mine(1)
	alpha Q6respect Q6listen Q6fair Q6explain
	egen pj = rmean(Q6respect Q6listen Q6fair Q6explain)

	* Police ineffectiveness // NOTE: Items are reverse coded
	gen RQ6satisfied = 5 - Q6satisfied
	gen RQ6presence = 5 - Q6presence

	correlate RQ6satisfied RQ6presence
	egen ineffective = rmean(RQ6satisfied RQ6presence)

	* Race
	gen black = 1 if race == 2
	replace black = 0 if race == 1
	
	drop if black == .

* Control variables
	* Distributive justice // note these get reverse coded
	gen RQ6minorities = 5 - Q6minorities
	gen RQ6wealthy = 5 - Q6wealthy
	
	correlate RQ6minorities RQ6wealthy
	egen dj = rmean(RQ6minorities RQ6wealthy)
	
	* Police contact
	gen police_contact = 0 if Q3contact == 0
	replace police_contact = 1 if Q3officer == 0 // citizen-initiated
	replace police_contact = 2 if Q3officer == 1 // police-initiated
	
	* Prior victimization
	factor Q4autotheft Q4autobreak Q4vandalism Q4breakandenter Q4assault_noweapon Q4assault_weapon Q4robbery, mine(1)
	alpha Q4autotheft Q4autobreak Q4vandalism Q4breakandenter Q4assault_noweapon Q4assault_weapon Q4robbery
	
	egen victimized = rmean(Q4autotheft Q4autobreak Q4vandalism Q4breakandenter Q4assault_noweapon Q4assault_weapon Q4robbery)
	
	sum victimized, d // super right-skewed
	gen ln_victimized = ln(victimized+1)
	
	* Collective efficacy
	gen RQ7getalong = 5 - Q7getalong
	gen RQ7values = 5 - Q7values
	
	factor Q7truancy Q7graffiti Q7disrespect Q7fight Q7firestation Q7help Q7closeknit Q7trust RQ7getalong RQ7values, mine(1)
	rotate
	alpha Q7truancy Q7graffiti Q7disrespect Q7fight Q7firestation 
	alpha Q7help Q7closeknit Q7trust RQ7getalong RQ7values
	alpha Q7truancy Q7graffiti Q7disrespect Q7fight Q7firestation Q7help Q7closeknit Q7trust RQ7getalong RQ7values
	
	egen collective = rmean(Q7truancy Q7graffiti Q7disrespect Q7fight Q7firestation Q7help Q7closeknit Q7trust RQ7getalong RQ7values)
	
	* Fear of crime
	gen RQ2fear = 5 - Q2fear
	
	factor Q2walkingalone Q2safeathome RQ2fear, mine(1)
	alpha Q2walkingalone Q2safeathome RQ2fear
	egen fear = rmean(Q2walkingalone Q2safeathome RQ2fear)
	
	* Perceived disorder
	factor Q1garbage Q1noise Q1vandalism Q1traffic Q1drinkpublic Q1drugs Q1loiter Q1gangs, mine(1)
	alpha Q1garbage Q1noise Q1vandalism Q1traffic Q1drinkpublic Q1drugs Q1loiter Q1gangs
	egen disorder = rmean(Q1garbage Q1noise Q1vandalism Q1traffic Q1drinkpublic Q1drugs Q1loiter Q1gangs)

	* Sex
	gen female = 1 if gender == 1
	replace female = 0 if gender == 0

	* Age
	replace age = . if age == 0

* Generate a missing flag
gen missing = 1 if legit == . | ineffective == . | pj == . | dj == . | female == . | black == . | age == . | education == . | police_contact == . | victimized ==. | disorder == . | collective == . | fear == . | low_crime_hood == .
tab missing

* Split contact variable up into dummies for descriptives table and correlation matrix
gen police_initiated = 1 if police_contact == 2
replace police_initiated = 0 if police_contact != 2

gen citizen_initiated = 1 if police_contact == 1
replace citizen_initiated = 0 if police_contact != 1

* ANALYSIS
* Table 1: Descriptive statistics
sum legit ineffective pj dj female black age education police_initiated citizen_initiated ln_victimized disorder low_crime_hood collective fear if missing != 1

* Correlation matrix
correlate legit ineffective pj dj female black age education police_initiated citizen_initiated ln_victimized disorder low_crime_hood collective fear if missing != 1

* Table 2 Model 1 // OLS model - no interaction
reg legit pj ineffective dj female black age education i.police_contact ln_victimized disorder low_crime_hood collective fear if missing != 1, cformat(%4.3f) pformat(%4.3f) sformat(%4.3f)

	* Get the standardized coefficients
	reg legit pj ineffective dj female black age education i.police_contact ln_victimized disorder low_crime_hood collective fear if missing != 1, cformat(%4.3f) pformat(%4.3f) sformat(%4.3f) beta

	* Report F to 3 decimal places, report p-values to 4 decimal places
	di %4.3f e(F)
	est tab, p(%10.4f)

	* Check variance inflation factors
	estat vif

* Table 2 Model 2 // OLS model w/interaction term
* Mean center PJ & Ineffectiveness
sum pj, meanonly
gen pj_c = pj - r(mean)

sum ineffective, meanonly
gen ineffective_c = ineffective - r(mean)

reg legit c.pj_c##c.ineffective_c dj female black age education i.police_contact ln_victimized disorder low_crime_hood collective fear if missing != 1, cformat(%4.3f) pformat(%4.3f) sformat(%4.3f)

	* Report F to 3 decimal places, report p-values to 4 decimal places
	di %4.3f e(F)
	est tab, p(%10.4f)

	* Figure 1: Margins & Marginsplot
	sum ineffective_c if missing != 1
	sum pj_c if missing != 1
	margins, at(ineffective_c=(-.659 0 .659) pj_c=(-.571 0 .591))
	marginsplot, xtitle("Police Ineffectiveness", size(medsmall) margin(0 0 0 3)) ///
	ytitle("Predicted Values of Police Legitimacy", size(medsmall)) ///
	leg(pos(6) size(small) rows(1) order(1 2 3) label(1 "-1SD Procedural Justice") label(2 "Mean Procedural Justice") label(3 "+1SD Procedural Justice")) ///
	xscale(range(-.659(1.318).659)) xlabel(-.659 "Low (-1SD)" 0 "Mean" .659 "High (+1SD)", labs(small)) graphr(margin(2 8 2 2)) ///
	title("") name(study1_fig1, replace)
	
	graph export "figure 1.png", as(png) name("study1_fig1") replace

	* Get the standardized coefficients
	reg legit c.pj_c##c.ineffective_c dj female black age education i.police_contact ln_victimized disorder low_crime_hood collective fear  if missing != 1, cformat(%4.3f) pformat(%4.3f) sformat(%4.3f) beta

* Table 3 Model 1 // OLS model w/interaction for black respondents only
reg legit c.pj_c##c.ineffective_c dj female age education i.police_contact ln_victimized disorder low_crime_hood collective fear if black == 1 & missing != 1, cformat(%4.3f) pformat(%4.3f) sformat(%4.3f)

	* Report F to 3 decimal places, report p-values to 4 decimal places
	di %4.3f e(F)
	est tab, p(%10.4f)

	* Get the standardized coefficients
	reg legit c.pj_c##c.ineffective_c dj female age education i.police_contact ln_victimized disorder low_crime_hood collective fear if black == 1 & missing != 1, cformat(%4.3f) pformat(%4.3f) sformat(%4.3f) beta

* Table 3 Model 2 // OLS model w/interaction for white respondents only
reg legit c.pj_c##c.ineffective_c dj female age education i.police_contact ln_victimized disorder low_crime_hood collective fear if black == 0 & missing != 1, cformat(%4.3f) pformat(%4.3f) sformat(%4.3f)

	* Report F to 3 decimal places, report p-values to 4 decimal places
	di %4.3f e(F)
	est tab, p(%10.4f)

	* Get the standardized coefficients
	reg legit c.pj_c##c.ineffective_c dj female age education i.police_contact ln_victimized disorder low_crime_hood collective fear if black == 0 & missing != 1, cformat(%4.3f) pformat(%4.3f) sformat(%4.3f) beta

	* Figure 2: Margins & Marginsplot
	reg legit c.pj_c##c.ineffective_c dj female black age education i.police_contact ln_victimized disorder low_crime_hood collective fear if missing != 1, cformat(%4.3f) pformat(%4.3f) sformat(%4.3f)
	margins, at(ineffective_c=(-.659 0 .659) pj_c=(-.571 .591) black=(0 1))
	marginsplot, xtitle("Police Ineffectiveness", size(medsmall) margin(0 0 0 3)) ///
	ytitle("Predicted Values of Police Legitimacy", size(medsmall)) ///
	leg(pos(6) size(small) rows(2) order(1 2 3 4) label(1 "White / -1SD PJ") label(2 "African American / -1SD PJ") label(3 "White / +1SD PJ") label(4 "African American / +1SD PJ")) ///
	xscale(range(-.659(1.318).659)) xlabel(-.659 "Low (-1SD)" 0 "Mean" .659 "High (+1SD)", labs(small)) graphr(margin(2 8 2 2)) ///
	title("") name(study1_fig2, replace)
	
	graph export "figure 2.png", as(png) name("study1_fig2") replace
	
log close

********************************************************************************
********************************************************************************
* Study 2

* Start a log for Study 2
log using "output_study2", replace

* Call up the data
import delimited "data_study2.csv", varnames(1) clear

drop in 1/2 // no data in these first two rows

* Attention check
tab qb, m
keep if qb == "About $1,500"

* Inclusion criteria
tab term
drop if term != "" // drops 42 respondents who didn't meet the inclusion criteria
	
* GENERATE VARIABLES FOR ANALYSIS
* Dependent variable: Police legitimacy
foreach i in q10_7 q10_8 q10_9 {
	replace `i' = "1" if `i' == "Strongly disagree"
	replace `i' = "2" if `i' == "Disagree"
	replace `i' = "3" if `i' == "Agree"
	replace `i' = "4" if `i' == "Strongly agree"
}

destring q10_7 q10_8 q10_9, replace

factor q10_7 q10_8 q10_9
alpha q10_7 q10_8 q10_9
egen legit = rmean(q10_7 q10_8 q10_9)

* Independent variables
	*Procedural justice
	foreach i in q10_1 q10_2 q10_3 q10_4 {
		replace `i' = "1" if `i' == "Strongly disagree"
		replace `i' = "2" if `i' == "Disagree"
		replace `i' = "3" if `i' == "Agree"
		replace `i' = "4" if `i' == "Strongly agree"
	}

	destring q10_1 q10_2 q10_3 q10_4, replace

	factor q10_1 q10_2 q10_3 q10_4
	alpha q10_1 q10_2 q10_3 q10_4
	egen pj = rmean(q10_1 q10_2 q10_3 q10_4)

	* Police ineffectiveness // NOTE: Items are reverse coded
	foreach i in q10_10 q10_11 {
		replace `i' = "4" if `i' == "Strongly disagree"
		replace `i' = "3" if `i' == "Disagree"
		replace `i' = "2" if `i' == "Agree"
		replace `i' = "1" if `i' == "Strongly agree"
	}

	destring q10_10 q10_11, replace

	correlate q10_10 q10_11
	egen ineffective = rmean(q10_10 q10_11)

	* Race
	gen black = 1 if q3 == "Black or African American"
	replace black = 0 if q3 == "White"

* Control variables
	* Distributive justice // note these get reverse coded
	foreach i in q10_5 q10_6 {
		replace `i' = "4" if `i' == "Strongly disagree"
		replace `i' = "3" if `i' == "Disagree"
		replace `i' = "2" if `i' == "Agree"
		replace `i' = "1" if `i' == "Strongly agree"
	}
	
	destring q10_5 q10_6, replace
	
	correlate q10_5 q10_6
	egen dj = rmean(q10_5 q10_6)
	
	* Police contact
	gen police_contact = 0 if q8_1 == "No"
	replace police_contact = 1 if q8_1 == "Yes" & q8_2 == "No" // citizen-initiated
	replace police_contact = 2 if q8_1 == "Yes" & q8_2 == "Yes" // police-initiated
	
	* Prior victimization
	foreach i in q9_1 q9_2 q9_3 q9_4 q9_5 q9_6 q9_7 {
		replace `i' = "0" if `i' == "0"
		replace `i' = "1" if `i' == "1"
		replace `i' = "2" if `i' == "2"
		replace `i' = "3" if `i' == "3"
		replace `i' = "4" if `i' == "4 or more"
	}
	
	destring q9_1 q9_2 q9_3 q9_4 q9_5 q9_6 q9_7, replace
	
	factor q9_1 q9_2 q9_3 q9_4 q9_5 q9_6 q9_7
	alpha q9_1 q9_2 q9_3 q9_4 q9_5 q9_6 q9_7
	
	egen victimized = rmean(q9_1 q9_2 q9_3 q9_4 q9_5 q9_6 q9_7)
	
	sum victimized, d // super right-skewed
	
	gen ln_victimized = ln(victimized+1)
	
	* Collective efficacy
	foreach i in q11_1 q11_2 q11_3 q11_4 q11_5 {
		replace `i' = "1" if `i' == "Very unlikely"
		replace `i' = "2" if `i' == "Unlikely"
		replace `i' = "3" if `i' == "Likely"
		replace `i' = "4" if `i' == "Very likely"
	}
	
	destring q11_1 q11_2 q11_3 q11_4 q11_5, replace
	
	foreach i in q12_1 q12_2 q12_3 q12_4 q12_5 {
		replace `i' = "1" if `i' == "Strongly disagree"
		replace `i' = "2" if `i' == "Disagree"
		replace `i' = "3" if `i' == "Agree"
		replace `i' = "4" if `i' == "Strongly agree"
	}
	
	destring q12_1 q12_2 q12_3 q12_4 q12_5, replace
	
	gen rq12_4 = 5 - q12_4
	gen rq12_5 = 5 - q12_5
	
	factor q11_1 q11_2 q11_3 q11_4 q11_5 q12_1 q12_2 q12_3 rq12_4 rq12_5, mine(1)
	rotate
	alpha q11_1 q11_2 q11_3 q11_4 q11_5
	alpha q12_1 q12_2 q12_3 rq12_4 rq12_5
	alpha q11_1 q11_2 q11_3 q11_4 q11_5 q12_1 q12_2 q12_3 rq12_4 rq12_5
	
	egen collective = rmean(q11_1 q11_2 q11_3 q11_4 q11_5 q12_1 q12_2 q12_3 rq12_4 rq12_5)
	
	* Fear of crime
	foreach i in q7_1 q7_2 q7_3 {
		replace `i' = "1" if `i' == "Strongly disagree"
		replace `i' = "2" if `i' == "Disagree"
		replace `i' = "3" if `i' == "Agree"
		replace `i' = "4" if `i' == "Strongly agree"
	}
	
	destring q7_1 q7_2 q7_3, replace
	
	gen rq7_3 = 5 - q7_3
	
	factor q7_1 q7_2 rq7_3, mine(1)
	alpha q7_1 q7_2 rq7_3
	egen fear = rmean(q7_1 q7_2 rq7_3)
	
	* Perceived disorder 
	foreach i in q6_1 q6_2 q6_3 q6_4 q6_5 q6_6 q6_7 q6_8 {
		replace `i' = "0" if `i' == "Not a problem"
		replace `i' = "1" if `i' == "Somewhat of a problem"
		replace `i' = "2" if `i' == "Serious problem"
	}
	
	destring q6_1 q6_2 q6_3 q6_4 q6_5 q6_6 q6_7 q6_8, replace
	
	factor q6_1 q6_2 q6_3 q6_4 q6_5 q6_6 q6_7 q6_8, mine(1)
	alpha q6_1 q6_2 q6_3 q6_4 q6_5 q6_6 q6_7 q6_8
	egen disorder = rmean(q6_1 q6_2 q6_3 q6_4 q6_5 q6_6 q6_7 q6_8)

	* Sex
	gen female = 1 if q2 == "Female"
	replace female = 0 if q2 == "Male"

	* Age
	destring q1, gen(age)
	drop if age < 18

	* Ethnicity
	gen hispanic = 1 if q4 == "Yes"
	replace hispanic = 0 if q4 == "No"

	* Education
	gen education = 1 if q5 == "Less than a high school diploma" | q5 == "High school diploma or GED"
	replace education = 2 if q5 == "Some college"
	replace education = 3 if q5 == "Technical or associate degree"
	replace education = 4 if q5 == "Bachelor's degree"
	replace education = 5 if q5 == "Master's or law degree (JD or LLM)" | q5 == "PhD or similar graduate degree"
	label define edu 1 "Up to HSD/GED" 2 "Some college" 3 "Tech/Assoc degree" 4 "Bachelor's degree" 5 "Masters +"
	label values education edu

* Generate a missing flag
gen missing = 1 if legit == . | ineffective == . | pj == . | dj == . | female == . | black == . | age == . | education == . | police_contact == . | victimized ==. | disorder == . | collective == . | fear == .
tab missing

* Split contact variable up into dummies for descriptives table and correlation matrix
gen police_initiated = 1 if police_contact == 2
replace police_initiated = 0 if police_contact != 2

gen citizen_initiated = 1 if police_contact == 1
replace citizen_initiated = 0 if police_contact != 1

* ANALYSIS
* Table 4: Descriptive statistics
sum legit ineffective pj dj female black age education police_initiated citizen_initiated ln_victimized disorder collective fear if missing != 1
correlate legit ineffective pj dj female black age education police_initiated citizen_initiated ln_victimized disorder collective fear if missing != 1

* Table 5 Model 1 // OLS model - no interaction
reg legit pj ineffective dj female black age education i.police_contact ln_victimized disorder collective fear if missing != 1, cformat(%4.3f) pformat(%4.3f) sformat(%4.3f)

	* Get the standardized coefficients
	reg legit pj ineffective dj female black age education i.police_contact ln_victimized disorder collective fear if missing != 1, cformat(%4.3f) pformat(%4.3f) sformat(%4.3f) beta

	* Report F to 3 decimal places, report p-values to 4 decimal places
	di %4.3f e(F)
	est tab, p(%10.4f)
	estat vif

* Table 5 Model 2 // OLS model w/interaction term
* Mean center PJ and ineffectiveness
sum pj, meanonly
gen pj_c = pj - r(mean)

sum ineffective, meanonly
gen ineffective_c = ineffective - r(mean)

reg legit c.pj_c##c.ineffective_c dj female black age education i.police_contact ln_victimized disorder collective fear if missing != 1, cformat(%4.3f) pformat(%4.3f) sformat(%4.3f)

	* Get the standardized coefficients
	reg legit c.pj_c##c.ineffective_c dj female black age education i.police_contact ln_victimized disorder collective fear  if missing != 1, cformat(%4.3f) pformat(%4.3f) sformat(%4.3f) beta

	* Report F to 3 decimal places, report p-values to 4 decimal places
	di %4.3f e(F)
	est tab, p(%10.4f)

	* Figure 3: Margins & Marginsplot
	sum ineffective_c if missing != 1
	sum pj_c if missing != 1
	margins, at(ineffective_c=(-.684 0 .684) pj_c=(-.717 0 .697))
	marginsplot, xtitle("Police Ineffectiveness", size(medsmall) margin(0 0 0 3)) ///
	ytitle("Predicted Values of Police Legitimacy", size(medsmall)) ///
	leg(pos(6) size(small) rows(1) order(1 2 3) label(1 "-1SD Procedural Justice") label(2 "Mean Procedural Justice") label(3 "+1SD Procedural Justice")) ///
	xscale(range(-.684(1.368).684)) xlabel(-.684 "Low (-1SD)" 0 "Mean" .684 "High (+1SD)", labs(small)) graphr(margin(2 8 2 2)) ///
	title("") name(study2_fig1, replace)
	
	graph export "figure 3.png", as(png) name("study2_fig1") replace
	
* Table 6 Model 1 // OLS model w/interaction for black respondents only
reg legit c.pj_c##c.ineffective_c dj female age education i.police_contact ln_victimized disorder collective fear if black == 1 & missing != 1, cformat(%4.3f) pformat(%4.3f) sformat(%4.3f)

	* Get the standardized coefficients
	reg legit c.pj_c##c.ineffective_c dj female age education i.police_contact ln_victimized disorder collective fear if black == 1 & missing != 1, cformat(%4.3f) pformat(%4.3f) sformat(%4.3f) beta

	* Report F to 3 decimal places, p-values to 4 decimal places
	di %4.3f e(F)
	est tab, p(%10.4f)

* Table 6 Model 2 // OLS model w/interaction for white respondents only
reg legit c.pj_c##c.ineffective_c dj female age education i.police_contact ln_victimized disorder collective fear if black == 0 & missing != 1, cformat(%4.3f) pformat(%4.3f) sformat(%4.3f)

	* Get the standardized coefficients
	reg legit c.pj_c##c.ineffective_c dj female age education i.police_contact ln_victimized disorder collective fear if black == 0 & missing != 1, cformat(%4.3f) pformat(%4.3f) sformat(%4.3f) beta

	* Report F to 3 decimal places, p-values to 4 decimal places
	di %4.3f e(F)
	est tab, p(%10.4f)

	* Figure 4: Margins & Marginsplot
	reg legit c.pj_c##c.ineffective_c dj female black age education i.police_contact ln_victimized disorder collective fear if missing != 1, cformat(%4.3f) pformat(%4.3f) sformat(%4.3f)
	margins, at(ineffective_c=(-.684 0 .684) pj_c=(-.717 .697) black=(0 1))
	marginsplot, xtitle("Police Ineffectiveness", size(medsmall) margin(0 0 0 3)) ///
	ytitle("Predicted Values of Police Legitimacy", size(medsmall)) ///
	leg(pos(6) size(small) rows(2) order(1 2 3 4) label(1 "White / -1SD PJ") label(2 "African American / -1SD PJ") label(3 "White / +1SD PJ") label(4 "African American / +1SD PJ")) ///
	xscale(range(-.684(1.368).684)) xlabel(-.684 "Low (-1SD)" 0 "Mean" .684 "High (+1SD)", labs(small)) graphr(margin(2 8 2 2)) ///
	title("") name(study2_fig2, replace)
	
	graph export "figure 4.png", as(png) name("study2_fig2") replace

********************************************************************************
* ROBUSTNESS CHECKS

	* Removing possible speeders
	destring durationinseconds, gen(speed)
	sum speed, detail // Median = 7.5 mins, fastest was 33 seconds, 5th percentile = 3.7 mins
	gen speeder = 1 if speed <= 120
	tab speeder missing // these 3 speeders got listwise deleted anyway
	drop speeder
	gen speeder = 1 if speed <= 180
	tab speeder missing // 2 possible speeders retained in main analysis
	
	* Descriptive statistics
	sum legit ineffective pj dj female black age education police_initiated citizen_initiated ln_victimized disorder collective fear if missing != 1 & speeder != 1
	correlate legit ineffective pj dj female black age education police_initiated citizen_initiated ln_victimized disorder collective fear if missing != 1 & speeder != 1

	* Table 5 Model 1 // OLS model - no interaction
	reg legit pj ineffective dj female black age education i.police_contact ln_victimized disorder collective fear if missing != 1 & speeder != 1, cformat(%4.3f) pformat(%4.3f) sformat(%4.3f)
	reg legit pj ineffective dj female black age education i.police_contact ln_victimized disorder collective fear if missing != 1 & speeder != 1, cformat(%4.3f) pformat(%4.3f) sformat(%4.3f) beta
	estat vif

	* Table 5 Model 2 // OLS model - ineffectiveness X pj interaction
	reg legit c.pj_c##c.ineffective_c dj female black age education i.police_contact ln_victimized disorder collective fear if missing != 1 & speeder != 1, cformat(%4.3f) pformat(%4.3f) sformat(%4.3f)
	reg legit c.pj_c##c.ineffective_c dj female black age education i.police_contact ln_victimized disorder collective fear  if missing != 1 & speeder != 1, cformat(%4.3f) pformat(%4.3f) sformat(%4.3f) beta

	* Table 6 Model 1 // OLS model w/interaction for black respondents only
	reg legit c.pj_c##c.ineffective_c dj female age education i.police_contact ln_victimized disorder collective fear if black == 1 & missing != 1 & speeder != 1, cformat(%4.3f) pformat(%4.3f) sformat(%4.3f)
	reg legit c.pj_c##c.ineffective_c dj female age education i.police_contact ln_victimized disorder collective fear if black == 1 & missing != 1 & speeder != 1, cformat(%4.3f) pformat(%4.3f) sformat(%4.3f) beta

	* Table 6 Model 2 // OLS model w/interaction for white respondents only
	reg legit c.pj_c##c.ineffective_c dj female age education i.police_contact ln_victimized disorder collective fear if black == 0 & missing != 1 & speeder != 1, cformat(%4.3f) pformat(%4.3f) sformat(%4.3f)
	reg legit c.pj_c##c.ineffective_c dj female age education i.police_contact ln_victimized disorder collective fear if black == 0 & missing != 1 & speeder != 1, cformat(%4.3f) pformat(%4.3f) sformat(%4.3f) beta
	
log close
