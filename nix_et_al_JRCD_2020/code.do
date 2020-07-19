/********************************************************************************************************
- Nix, Pickett, & Wolfe (2020)
- "Testing a Theoretical Model of Perceived Audience Legitimacy"
- Journal of Research in Crime and Delinquency, 57(2), 217-259
- Code written 8/20/2018
- Last updated 8/9/2019
- All analyses performed in Stata v15
********************************************************************************************************/


******************************************************************************
* STUDY #1: ANONYMOUS POLICE DEPARTMENT
* Administered January 15 - February 3 via SurveyMonkey
******************************************************************************

* Call up data for Study 1
	use "~\Study1.dta" 

/* drop 5 blank surveys */
	drop if q0001 == .

* CREATE VARIABLES

* DV: Perceived Audience Legitimacy
	alpha q0027*
	egen Raud = rmean(q0027*)
	gen aud = 6 - Raud

* IV: Personal experience with verbal mistreatment in the last year
	clonevar Q4a = q0004_0001
	clonevar Q4b = q0004_0002
	clonevar Q4c = q0004_0003
	replace  Q4a = q0011_0001 if q0004_0001 ==. & q0011_0001 !=.
	replace  Q4b = q0011_0002 if q0004_0002 ==. & q0011_0002 !=.
	replace  Q4c = q0011_0003 if q0004_0003 ==. & q0011_0003 !=.
	factor Q4*, mine(1)
	alpha Q4*
	egen mistreat = rmean(Q4*)
	sum mistreat

* IV: Citizen Animus
	clonevar Q3a = q0003_0001
	clonevar Q3b = q0003_0002
	clonevar Q3c = q0003_0003
	clonevar Q3d = q0003_0004
	clonevar Q3e = q0003_0005
	clonevar Q3f = q0003_0006 
	clonevar Q3g = q0003_0007
	replace  Q3a = q0010_0001 if q0003_0001 ==. & q0010_0001 !=.
	replace  Q3b = q0010_0002 if q0003_0002 ==. & q0010_0002 !=.
	replace  Q3c = q0010_0003 if q0003_0003 ==. & q0010_0003 !=.
	replace  Q3d = q0010_0004 if q0003_0004 ==. & q0010_0004 !=.
	replace  Q3e = q0010_0005 if q0003_0005 ==. & q0010_0005 !=.
	replace  Q3f = q0010_0006 if q0003_0006 ==. & q0010_0006 !=.
	replace  Q3g = q0010_0007 if q0003_0007 ==. & q0010_0007 !=.
	alpha Q3*
	gen RQ3a = 6 - Q3a
	gen RQ3d = 6 - Q3d
	gen RQ3e = 6 - Q3e
	gen RQ3g = 6 - Q3g
	egen animus = rmean(RQ3a Q3b Q3c RQ3d RQ3e Q3f RQ3g)
	sum animus

* IV: Perceived crime trend over last three years
	clonevar Q5 = q0005
	replace  Q5 = q0012 if q0005 ==. & q0012 !=.
	gen pcrime = 6 - Q5

* Controls
	recode q0036 (2 = 1) (1 = 0), gen (Male)
	gen Age = 2018 - q0037_0001
	recode Age (111 348 1148 = .)
	recode q0039 (1=1) (2 3 4 0 = 0), gen (White)
	replace White = 0 if q0038 == 1
	recode q0040 (1/4 = 0) (5/7 = 1), gen (BachDegree)
	clonevar CJYears = q0041_0001
	recode q0042 (6 = 0) (4/5 = 1) (1/3 = 2), gen(Rank)
	label define Rank 0 "0. Police Officer" 1 "1. Front-line Supervisor" 2 "2. Command Staff"
	label values Rank Rank

* separate the Rank variable into dummies for sgmediation later on
	gen sup = 1 if Rank == 1
	replace sup = 0 if Rank == 0 | Rank == 2
	gen com = 1 if Rank == 2
	replace com = 0 if Rank == 0 | Rank == 1
	gen patrol = 1 if Rank == 0
	replace patrol = 0 if Rank == 1 | Rank == 2

* factor analyze animus and audience legitimacy items to ensure they load separately
	factor RQ3a Q3b Q3c RQ3d RQ3e Q3f RQ3g q0027*, mine(1) // two factors
	rotate, promax blanks(.3)
	/* animus:  E=3.72, loadings .46 - .76
	   aud:     E=1.20, loadings .73 - .85 */  
   
* factor analyze animus and mistreat to demonstrate for Reviewer 3 that they are conceptually distinct
	factor RQ3a Q3b Q3c RQ3d RQ3e Q3f RQ3g Q4*, mine(1) // two factors
	rotate, promax blanks(.3)
	/* animus:   E=4.14, loadings .51 to .73
	   mistreat: E=1.26, loadings .89 to .94 */
   
   
* create "missing" variable
	gen missing = 0
	replace missing = 1 if aud == . | ///
						   mistreat == . | ///
						   animus == . | ///
						   pcrime == . | ///
						   Male == . | ///
						   White == . | ///
						   BachDegree == . | ///
						   CJYears == . | ///
						   Rank ==. 
	tab missing

	
***** MAIN ANALYSES *****

* Table 1: Descriptives w/listwise deleted data
	sum aud mistreat animus pcrime Male White BachDegree CJYears patrol sup com

* Correlation Matrix w/listwise deleted data 
	pwcorr aud mistreat animus pcrime Male White BachDegree CJYears sup com, listwise star(.05)
	tetrachoric Male White BachDegree sup com if missing == 0, star(.05)

* compare missing to non-missing group on DV and IV to see if we meet MAR assumption
	ttest aud, by(missing)
	ttest animus, by(missing)

	mcartest aud mistreat animus pcrime Male White BachDegree CJYears sup com // p = .34

* Multiple Imputation
	mi set flong
	mi register impute aud mistreat animus pcrime Male White BachDegree CJYears sup com
	mi impute mvn aud mistreat animus pcrime Male White BachDegree CJYears sup com, add(25) rseed(112317)

* Table 1: Descriptives w/MI data
	mi estimate: mean aud mistreat animus pcrime Male White BachDegree CJYears sup com
	misum aud mistreat animus pcrime Male White BachDegree CJYears sup com

* Table 2: OLS regression models predicting audience legitimacy
	mi estimate: regress aud mistreat Male White BachDegree CJYears sup com, robust
	mi estimate: regress aud animus Male White BachDegree CJYears sup com, robust
	mi estimate: regress aud pcrime Male White BachDegree CJYears sup com, robust
	mi estimate: regress aud mistreat animus pcrime Male White BachDegree CJYears sup com, robust


* indirect effect of mistreatment
	mi estimate (ind_eff: [animus]_b[mistreat]*[aud]_b[animus]) ///
	    (tot_eff: [animus]_b[mistreat]*[aud]_b[animus] + [aud]_b[mistreat]), cmdok: ///
		sureg (animus mistreat pcrime Male White BachDegree CJYears sup com)(aud animus mistreat pcrime Male White BachDegree CJYears sup com)
	display -.0883478/-.1417115 // proportion of total effect that is mediated
	
* indirect effect of perceived crime
	mi estimate (ind_eff: [animus]_b[pcrime]*[aud]_b[animus]) ///
	    (tot_eff: [animus]_b[pcrime]*[aud]_b[animus] + [aud]_b[pcrime]), cmdok: ///
		sureg (animus pcrime mistreat Male White BachDegree CJYears sup com)(aud animus pcrime mistreat Male White BachDegree CJYears sup com)
	display -.0649387/-.1608059 // proportion of total effect that is mediated
	
* EDITOR'S COMMENT: indirect effect of animus through mistreatment?
	mi estimate (ind_eff: [mistreat]_b[animus]*[aud]_b[mistreat]) ///
		(tot_eff: [mistreat]_b[animus]*[aud]_b[mistreat] + [aud]_b[animus]), cmdok: ///
		sureg (mistreat animus pcrime Male White BachDegree CJYears sup com)(aud mistreat animus pcrime Male White BachDegree CJYears sup com)
	display -.0417474/-.4360425 // proportion of total effect that is mediated	

	

***** SUPPLEMENTAL ANALYSES USING LISTWISE DELETION *****

sum aud mistreat animus pcrime Male White BachDegree CJYears patrol sup com
correlate aud mistreat animus pcrime Male White BachDegree CJYears patrol sup com

* Model 1: OLS regression of audience legitimacy onto personal experience with mistreatment
	regress aud mistreat Male White BachDegree CJYears i.Rank if missing != 1, robust
	est sto m1

* Model 2: OLS regression of audience legitimacy onto perceived citizen animus
	regress aud animus Male White BachDegree CJYears i.Rank if missing != 1, robust
	est sto m2

* Model 3: OLS regression of audience legitimacy onto perceived crime trend
	regress aud pcrime Male White BachDegree CJYears i.Rank if missing != 1, robust
	est sto m3

* Model 4: Fully saturated model
	regress aud mistreat animus pcrime Male White BachDegree CJYears i.Rank if missing != 1, robust
	est sto m4
	estat vif
	estat sum // Table 1: descriptives for analytic sample

/* Check to see if animus mediates the effect of mistreatment on audience legitimacy */
	sgmediation aud, iv(mistreat) mv(animus) cv(pcrime Male White BachDegree CJYears sup com)			
	quietly bootstrap r(ind_eff), reps(1000) seed(1983): quietly sgmediation aud, ///
					  iv(mistreat) mv(animus) cv(pcrime Male White BachDegree CJYears sup com)
	estat bootstrap, percentile bc

/* Check to see if animus mediates the effect of perceived crime on audience legitimacy */
	sgmediation aud, iv(pcrime) mv(animus) cv(mistreat Male White BachDegree CJYears sup com)			
	quietly bootstrap r(ind_eff), reps(1000) seed(1983): quietly sgmediation aud, ///
					  iv(pcrime) mv(animus) cv(mistreat Male White BachDegree CJYears sup com)
	estat bootstrap, percentile bc
	

	

/****************************************************************************** 
STUDY #2: NATIONAL SURVEY OF POLICE CHIEFS
Mail/online survey administered between 2/18/2018 and 4/16/2018
*******************************************************************************/

* Call up the data for Study 2
use "~\Study2.dta", clear

* CREATE VARIABLES

* DV: audience legitimacy
	alpha q9*
	gen rq9b = 6 - q9b
	gen rq9c = 6 - q9c
	gen rq9d = 6 - q9d
	gen rq9f = 6 - q9f
	gen rq9g = 6 - q9g
	egen aud = rmean(q9a rq9b rq9c rq9d q9e rq9f rq9g)
	label var aud "Audience Legitimacy"
	sum aud, detail

* for supplemental analysis: disaggregate DV into 4 subscales: PJ, DJ, Lawfulness, Effectiveness
	egen pj  = rmean(rq9c rq9d)
	egen dj  = rmean(rq9b q9e)
	egen law = rmean(q9a rq9g)
	clonevar eff = rq9g

* IV: perceived animus
	alpha q5*
	gen rq5a = 6 - q5a
	gen rq5d = 6 - q5d
	gen rq5e = 6 - q5e
	gen rq5g = 6 - q5g
	egen animus = rmean(rq5a q5b q5c rq5d rq5e q5f rq5g)
	tab  animus

* factor analyze animus and audience legitimacy items to ensure they load separately
	factor rq5a q5b q5c rq5d rq5e q5f rq5g q9a rq9b rq9c rq9d q9e rq9f rq9g, mine(1)
	rotate, promax blanks(.3)

* IVs: hostile media (national and local)
	// nat'l media loadings (.75 - .83)
	// local media loadings (.84 - .86)
	alpha q8a q8b q8c q8d
	alpha q8e q8f q8g q8h
	egen nmedia = rmean(q8a q8b q8c q8d) // nat'l media
	label var nmedia "Hostile Nat'l Media"
	egen lmedia = rmean(q8e q8f q8g q8h) // local media
	label var lmedia "Hostile Local Media"
	sum nmedia, detail
	sum lmedia, detail

* IV: average violent crime rate, 2014 to 2016
	gen vcrate16 = (vcrime16/ucrpop16)*100000
	gen vcrate15 = (vcrime15/ucrpop15)*100000
	gen vcrate14 = (vcrime14/ucrpop14)*100000
	egen avgvcrate = rmean(vcrate14 vcrate15 vcrate16)
	label var avgvcrate "Avg. Violent Crime Rate, 2014-16"
	gen ln_avgvcrate = ln(avgvcrate+1) // reduce skew
	label var ln_avgvcrate "ln(Avg. Violent Crime Rate, 2014-16)"

* IV: %black
	gen pblack = (black2016/pop2016)*100
	label var pblack "%Black, 2016"
	gen ln_pblack = ln(pblack+1) // reduce skew and add constant to deal with values < 1
	label var ln_pblack "ln(%Black, 2016)"

* IV: %hispanic
	gen phisp = (hisp2016/pop2016)*100
	label var phisp "%Hispanic, 2016"
	gen ln_phisp = ln(phisp+1) // reduce skew
	label var ln_phisp "ln(%Hispanic, 2010)"

* IV: % growth in black population
	gen pblack00 = (black2000/pop2000)*100
	gen blackgrowth = pblack - pblack00
	gen ln_blackgrowth = ln(blackgrowth+16)
	sum ln_blackgrowth, detail

* IV: % growth in hispanic population
	gen phisp00 = (hisp2000/pop2000)*100
	gen hispgrowth = phisp - phisp00
	gen ln_hispgrowth = ln(hispgrowth+10)
	sum ln_hispgrowth, detail


* CONTROL VARIABLES 

	gen male = .
	replace male = 0 if q19 == 0 & mode == 1
	replace male = 1 if q19 == 1 & mode == 1
	replace male = 1 if q19 == 1 & mode == 0
	replace male = 0 if q19 == 2 & mode == 0
	tab male

	gen age = 2018 - q20
	tab age
	replace age = 66 if id == 493 // respondent born in 1952
	replace age =  . if id == 526 // respondent wrote 19417, can't say for sure if he meant '41 or '47
	sum age

	gen hispanic = .
	replace hispanic = 0 if q21 == 0 & mode == 1
	replace hispanic = 1 if q21 == 1 & mode == 1
	replace hispanic = 1 if q21 == 1 & mode == 0
	replace hispanic = 0 if q21 == 2 & mode == 0
	tab hispanic

	gen white = .
	replace white = 0 if (q22 == 2 | q22 == 3 | q22 == 4 | q22 == 5) & mode == 1
	replace white = 1 if q22 == 1 & mode == 1
	replace white = 0 if (q22 == 2 | q22 == 3 | q22 == 4 | q22 == 0) & mode == 0
	replace white = 1 if q22 == 1  & mode == 0
	replace white = 0 if hispanic == 1
	tab white

	gen whitemale = 1 if male == 1 & white == 1
	replace whitemale = 0 if male == 0 | white == 0
	tab whitemale

	gen masters = . 
	replace masters = 1 if q23 == 6 | q23 == 7 // MA/JD or PhD
	replace masters = 0 if q23 >= 1 & q23 <= 5 // less than MA/JD
	tab masters

	gen chief = 0
	replace chief = . if q2 == " "
	replace chief = 1 if q2 == "chief" | ///
						 q2 == "Chief of Police" | ///
						 q2 == "Chief of police" | ///
						 q2 == "Chief/Director of Public Safety" | ///
						 q2 == "Chief" | ///
						 q2 == "Police Chief" | ///
						 q2 == "interim chief" | ///
						 q2 == "Acting Chief of Police" | ///
						 q2 == "Police Commissioner" | ///
						 q2 == "director" | ///
						 q2 == "CHIEF" | ///
						 q2 == "CHIEF OF POLICE" | ///
						 q2 == "Director" | ///
						 q2 == "Director (Chief)" | ///
						 q2 == "Director of Public Safety" | ///
						 q2 == "Interim Chief of Police" | ///
						 q2 == "Superintendent" | ///
						 q2 == "acting chief" | ///
						 q2 == "commissioner" | ///
						 q2 == "public safety director"
	tab chief					 					 
					 					 
	clonevar LEyrs = q24
	replace LEyrs = 23 if id == 454 // respondent wrote "years" after 23
	replace LEyrs = 23 if id == 568 // respondent wrote "years" after 23
	replace LEyrs = 30 if id == 540 // respondent wrote 30+
	replace LEyrs = 30 if id == 532 // respondent wrote 30+
	replace LEyrs = 33 if id == 384 // respondent wrote 33+
	replace LEyrs = 15 if id == 649 // following 6 respondents spelled number out
	replace LEyrs = 40 if id == 493
	replace LEyrs = 42 if id == 584
	replace LEyrs = 45 if id == 603
	replace LEyrs = 35 if id == 659
	replace LEyrs = 32 if id == 504
	sum LEyrs

	gen region = .
	replace region = 0 if state == "de"
	replace region = 0 if state == "dc"
	replace region = 0 if state == "fl"
	replace region = 0 if state == "ga"
	replace region = 0 if state == "md"
	replace region = 0 if state == "nc"
	replace region = 0 if state == "sc"
	replace region = 0 if state == "va"
	replace region = 0 if state == "wv"
	replace region = 0 if state == "al"
	replace region = 0 if state == "ky"
	replace region = 0 if state == "ms"
	replace region = 0 if state == "tn"
	replace region = 0 if state == "ar"
	replace region = 0 if state == "la"
	replace region = 0 if state == "ok"
	replace region = 0 if state == "tx"

	replace region = 1 if state == "ct"
	replace region = 1 if state == "me" 
	replace region = 1 if state == "ma" 
	replace region = 1 if state == "nh" 
	replace region = 1 if state == "ri" 
	replace region = 1 if state == "vt" 
	replace region = 1 if state == "nj" 
	replace region = 1 if state == "ny"
	replace region = 1 if state == "pa"

	replace region = 2 if state == "il"
	replace region = 2 if state == "in"
	replace region = 2 if state == "mi"
	replace region = 2 if state == "oh"
	replace region = 2 if state == "wi"
	replace region = 2 if state == "ia"
	replace region = 2 if state == "ks"
	replace region = 2 if state == "mn"
	replace region = 2 if state == "mo"
	replace region = 2 if state == "ne"
	replace region = 2 if state == "nd"
	replace region = 2 if state == "sd"

	replace region = 3 if state == "az"
	replace region = 3 if state == "co"
	replace region = 3 if state == "id"
	replace region = 3 if state == "mt"
	replace region = 3 if state == "nv"
	replace region = 3 if state == "nm"
	replace region = 3 if state == "ut"
	replace region = 3 if state == "wy"
	replace region = 3 if state == "ak"
	replace region = 3 if state == "ca"
	replace region = 3 if state == "hi"
	replace region = 3 if state == "or"
	replace region = 3 if state == "wa"
	label define region 0 "south" 1 "northeast" 2 "midwest" 3 "west"				 
	label values region region
	fre region

* split region variable into dummies for sgmediation later on
	gen ne = 1 if region == 1
	replace ne = 0 if region != 1
	replace ne = . if region == .

	gen mw = 1 if region == 2
	replace mw = 0 if region != 2
	replace mw = . if region == .

	gen we = 1 if region == 3
	replace we = 0 if region != 3
	replace we = . if region == .

	gen so = 1 if region == 0
	replace so = 0 if region != 0
	replace so = . if region == .

* pop2016 and unemployment are skewed, so needs to be transformed
	gen ln_pop2016 = ln(pop2016)
	label var ln_pop2016 "ln(Population, 2016)"

	gen ln_unemployment = ln(unemployment+1)

* create "missing" variable for easy exclusion from models 1 & 2
	gen missing = 0
	replace missing = 1 if aud == . | ///
						   animus == . | ///
						   ln_avgvcrate == . | ///
						   nmedia == . | ///
						   lmedia == . | ///
						   chief == . | ///
						   LEyrs == . | ///
						   masters == . | ///
						   whitemale == . | ///
						   sworn2 == . | ///
						   region == . | ///
						   ln_pop2016 == . | ///
						   ln_pblack == . | ///
						   ln_blackgrowth == . | ///
						   ln_phisp == . | ///
						   ln_hispgrowth == . | ///
						   ln_unemployment == . | ///
						   PercentTrump == .
	tab missing

* CREATE SAMPLING WEIGHTS 
	/* 
	For each stratum, divide [% of sample frame] by [% of sample] to generate weight variable:

	 0-24: 74.26/22.41 = 3.3137
	25-49: 13.38/25.86 =  .5174
	50-99:  6.93/25.26 =  .2743
	 100+:  5.43/26.47 =  .2051
	 
	*/

* Table 4: Post-stratification weighting procedure
	gen fweight = .
	replace fweight =  .2051 if sworn == 4
	replace fweight =  .2743 if sworn == 3
	replace fweight =  .5174 if sworn == 2
	replace fweight = 3.3137 if sworn == 1
	tab fweight sworn 

	svyset _n [pweight=fweight] // use this to apply weights to sgmediation command

* Correlation matrix using listwise deleted data
	corr_svy aud animus lmedia nmedia ln_avgvcrate ln_pblack ln_phisp ln_blackgrowth ///
			 ln_hispgrowth chief LEyrs masters sworn2 whitemale ne mw we ln_pop2016 ///
			 ln_unemployment PercentTrump [pweight=fweight], star(.05)
		


***** MAIN ANALYSES *****

* Table 3: Listwise Deleted Descriptives

local descrip "aud animus lmedia nmedia ln_avgvcrate ln_pblack ln_phisp ln_blackgrowth ln_hispgrowth chief LEyrs masters sworn2 whitemale ne mw we ln_pop2016 ln_unemployment PercentTrump"
foreach i in `descrip' {
	svy: mean `i'
	estat sd
	}
	
* compare missing to non-missing group on DV and IV to see if we meet MAR assumption
	ttest aud, by(missing)
	ttest animus, by(missing)

	mcartest aud animus lmedia nmedia ln_avgvcrate ln_pblack ln_phisp ln_blackgrowth ///
				 ln_hispgrowth chief LEyrs masters sworn2 whitemale ///
				 ne mw we ln_pop2016 ln_unemployment PercentTrump // p = .000
	
* Multiple Imputation
	mi set flong
	mi register impute aud animus ln_avgvcrate ln_pblack ln_blackgrowth ln_phisp ///
				ln_hispgrowth lmedia nmedia chief LEyrs masters sworn2 whitemale ///
				ne mw we ln_pop2016 ln_unemployment PercentTrump
	mi impute mvn aud animus ln_avgvcrate ln_pblack ln_blackgrowth ln_phisp ///
			  ln_hispgrowth lmedia nmedia chief LEyrs masters sworn2 whitemale ///
			  ne mw we ln_pop2016 ln_unemployment PercentTrump, add(25) rseed(112317)
		  
/*
* Multiple Imputation for Supplemental Models using Disaggregated DVs
	mi set mlong
	mi register impute pj dj law eff animus ln_avgvcrate ln_pblack ln_blackgrowth ln_phisp ///
				ln_hispgrowth lmedia nmedia chief LEyrs masters sworn2 whitemale ///
				ne mw we ln_pop2016 ln_unemployment PercentTrump
	mi impute mvn pj dj law eff animus ln_avgvcrate ln_pblack ln_blackgrowth ln_phisp ///
			  ln_hispgrowth lmedia nmedia chief LEyrs masters sworn2 whitemale ///
			  ne mw we ln_pop2016 ln_unemployment PercentTrump, add(25) rseed(112317)
*/

* Table 3: Multiple Imputation Descriptives
	mi estimate: mean aud animus lmedia nmedia ln_avgvcrate ln_pblack ln_phisp ln_blackgrowth ///
				 ln_hispgrowth chief LEyrs masters sworn2 whitemale ///
				 ne mw we ln_pop2016 ln_unemployment PercentTrump [pweight=fweight]

	misum aud animus lmedia nmedia ln_avgvcrate ln_pblack ln_phisp ln_blackgrowth ///
				 ln_hispgrowth chief LEyrs masters sworn2 whitemale ///
				 ne mw we ln_pop2016 ln_unemployment PercentTrump [aweight=fweight]
	 
* Table 4: OLS regression models predicting audience legitimacy
	mibeta  aud animus chief LEyrs masters sworn2 whitemale ne mw we ///
				 ln_pop2016 ln_unemployment PercentTrump [pweight=fweight], robust
				 
	mibeta  aud lmedia nmedia chief LEyrs masters sworn2 whitemale ne ///
				 mw we ln_pop2016 ln_unemployment PercentTrump [pweight=fweight], robust
				 
	mibeta  aud ln_avgvcrate chief LEyrs masters sworn2 whitemale ne ///
				 mw we ln_pop2016 ln_unemployment PercentTrump [pweight=fweight], robust
				 
	mibeta  aud ln_pblack ln_phisp ln_blackgrowth ln_hispgrowth chief ///
				 LEyrs masters sworn2 whitemale ne mw we ln_pop2016 ln_unemployment ///
				 PercentTrump [pweight=fweight], robust

	mibeta  aud animus lmedia nmedia ln_avgvcrate ln_pblack ln_phisp ln_blackgrowth ///
				 ln_hispgrowth chief LEyrs masters sworn2 whitemale ///
				 ne mw we ln_pop2016 ln_unemployment PercentTrump [pweight=fweight], robust
			 


* indirect effect of percent black?
	mi estimate (ind_eff: [animus]_b[ln_pblack]*[aud]_b[animus]) ///
				(tot_eff: [animus]_b[ln_pblack]*[aud]_b[animus] + [aud]_b[ln_pblack]), cmdok: ///
	   sureg (animus ln_pblack lmedia nmedia ln_avgvcrate ln_phisp ln_blackgrowth ///
			  ln_hispgrowth chief LEyrs masters sworn2 whitemale ///
			  ne mw we ln_pop2016 ln_unemployment PercentTrump) ///
			 (aud animus ln_pblack lmedia nmedia ln_avgvcrate ln_phisp ln_blackgrowth ///
			  ln_hispgrowth chief LEyrs masters sworn2 whitemale ///
			  ne mw we ln_pop2016 ln_unemployment PercentTrump) 
	display -.0116316/-.0483501 // proportion of total effect that is mediated	

* indirect effect of local media
	mi estimate (ind_eff: [animus]_b[lmedia]*[aud]_b[animus]) ///
				(tot_eff: [animus]_b[lmedia]*[aud]_b[animus] + [aud]_b[lmedia]), cmdok: ///
	   sureg (animus lmedia nmedia ln_avgvcrate ln_pblack ln_phisp ln_blackgrowth ///
			  ln_hispgrowth chief LEyrs masters sworn2 whitemale ///
			  ne mw we ln_pop2016 ln_unemployment PercentTrump) ///
			 (aud animus lmedia lmedia nmedia ln_avgvcrate ln_phisp ln_blackgrowth ///
			  ln_hispgrowth chief LEyrs masters sworn2 whitemale ///
			  ne mw we ln_pop2016 ln_unemployment PercentTrump) 		 


* unweighted means of 25 imputed datasets
	mi estimate: mean aud animus lmedia nmedia ln_avgvcrate ln_pblack ln_blackgrowth ///
				 ln_phisp ln_hispgrowth chief LEyrs masters sworn2 whitemale ///
				 ne mw we ln_pop2016 ln_unemployment PercentTrump if fweight!=.
			 
			 

***** SUPPLEMENTAL ANALYSES USING LISTWISE DELETION *****


* Model 1: OLS regression of audience legitimacy onto animus
	regress aud animus chief LEyrs masters sworn2 whitemale ne mw we ln_pop2016 ln_unemployment ///
			PercentTrump [pweight=fweight] if missing != 1, robust
	est sto m1
	di %6.3f e(F)

* Model 2: OLS regression of audience legitimacy onto hostile media perceptions
	regress aud lmedia nmedia chief LEyrs masters sworn2 whitemale ne mw we ln_pop2016 ln_unemployment ///
			PercentTrump [pweight=fweight] if missing != 1, robust
	est sto m4
	di %6.3f e(F)

* Model 3: OLS regression of audience legitimacy onto violent crime
	regress aud ln_avgvcrate chief LEyrs masters sworn2 whitemale ne mw we ln_pop2016 ln_unemployment ///
			PercentTrump [pweight=fweight] if missing != 1, robust
	est sto m2
	di %6.3f e(F)

* Model 4: OLS regression of audience legitimacy onto racial threat variables
	regress aud ln_pblack ln_blackgrowth ln_phisp ln_hispgrowth chief LEyrs masters sworn2 whitemale ne mw we ln_pop2016 ln_unemployment ///
			PercentTrump [pweight=fweight] if missing != 1, robust
	est sto m3
	di %6.3f e(F)

* Model 5: Fully saturated model
	regress aud animus lmedia nmedia ln_avgvcrate ln_pblack ln_blackgrowth ln_phisp ln_hispgrowth chief LEyrs masters sworn2 whitemale ///
			ne mw we ln_pop2016 ln_unemployment PercentTrump [pweight=fweight] if missing != 1, robust
	est sto m5
	estat vif // none exceed 2.85, mean = 1.77
	estat sum // Table 4: weighted summary stats
	di %6.3f e(F)

* unweighted summary stats for Table 4
	sum aud animus lmedia nmedia ln_avgvcrate ln_pblack ln_blackgrowth ln_phisp ln_hispgrowth chief LEyrs ///
		masters sworn2 whitemale i.region ln_pop2016 ln_unemployment PercentTrump ///
		if missing !=1

* check bivariate correlations
	correlate aud animus lmedia nmedia ln_avgvcrate ln_pblack ln_blackgrowth ln_phisp ln_hispgrowth chief LEyrs masters sworn2 whitemale ///
			ne mw we ln_pop2016 ln_unemployment PercentTrump if missing != 1 // none exceed .66

* does animus mediate the effect of violent crime on audience legitimacy
	sgmediation aud, iv(ln_avgvcrate) mv(animus) cv(lmedia nmedia ln_pblack ln_blackgrowth ln_phisp ln_hispgrowth chief ///
				LEyrs masters sworn2 whitemale ne mw we ln_pop2016 ln_unemployment PercentTrump) prefix(svy:)
	quietly bootstrap r(ind_eff), reps(1000) seed(1983): quietly sgmediation aud, ///
					  iv(ln_avgvcrate) mv(animus) cv(ln_pblack ln_blackgrowth ln_phisp ln_hispgrowth lmedia nmedia chief ///
					  LEyrs masters sworn2 whitemale ne mw we ln_pop2016 ln_unemployment PercentTrump) prefix(svy:)
	estat bootstrap, percentile bc


* does animus mediate the effect of hostile media on audience legitimacy
	sgmediation aud, iv(lmedia) mv(animus) cv(nmedia ln_avgvcrate ln_pblack ln_blackgrowth ln_phisp ln_hispgrowth chief ///
				LEyrs masters sworn2 whitemale ne mw we ln_pop2016 ln_unemployment PercentTrump) prefix(svy:)
	quietly bootstrap r(ind_eff), reps(1000) seed(1983): quietly sgmediation aud, ///
					  iv(lmedia) mv(animus) cv(ln_avgvcrate ln_pblack ln_blackgrowth ln_phisp ln_hispgrowth nmedia chief ///
					  LEyrs masters sworn2 whitemale ne mw we ln_pop2016 ln_unemployment PercentTrump) prefix(svy:)
	estat bootstrap, percentile bc



***** SUPPLEMENTAL ANALYSES USING DISAGGREGATED DVS *****
	mibeta pj animus lmedia nmedia ln_avgvcrate ln_pblack ln_phisp ln_blackgrowth ///
				 ln_hispgrowth chief LEyrs masters sworn2 whitemale ///
				 ne mw we ln_pop2016 ln_unemployment PercentTrump [pweight=fweight], robust

	mibeta dj animus lmedia nmedia ln_avgvcrate ln_pblack ln_phisp ln_blackgrowth ///
				 ln_hispgrowth chief LEyrs masters sworn2 whitemale ///
				 ne mw we ln_pop2016 ln_unemployment PercentTrump [pweight=fweight], robust
				 
	mibeta law animus lmedia nmedia ln_avgvcrate ln_pblack ln_phisp ln_blackgrowth ///
				 ln_hispgrowth chief LEyrs masters sworn2 whitemale ///
				 ne mw we ln_pop2016 ln_unemployment PercentTrump [pweight=fweight], robust
				 
	mi estimate: ologit eff animus lmedia nmedia ln_avgvcrate ln_pblack ln_phisp ln_blackgrowth ///
				 ln_hispgrowth chief LEyrs masters sworn2 whitemale ///
				 ne mw we ln_pop2016 ln_unemployment PercentTrump [pweight=fweight], robust 
