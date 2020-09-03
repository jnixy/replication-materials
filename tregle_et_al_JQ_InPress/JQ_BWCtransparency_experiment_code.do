/* 
2018 National Police Executive Survey
Data collection began 2/18/2018 and ended 4/16/2018
3 waves (postcard, survey, survey) sent to 2,496 agencies, blocked according to size
704 surveys returned,
29 duplicates identified and removed,
total = 675; RR = 27%
also removed 1 sheriff's department, 1 state police department, and 8 departments that we couldn't place in a stratum
N = 665
*/

version 15.1

* CREATE VARIABLES

	* Dummy for whether respondent was Chief
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

	* Drop 181 respondents who weren't the chief, N should go to 476
		drop if chief != 1

	* Create ordinal variable for number of full-time sworn officers currently employed
		gen sworn = . 
		replace sworn = 1 if q4 >=  0 & q4 <= 24
		replace sworn = 2 if q4 >= 25 & q4 <= 49
		replace sworn = 3 if q4 >= 50 & q4 <= 99
		replace sworn = 0 if q4 >= 100
		replace sworn = . if q4 == .
		label define sworn 1 "0 - 24" 2 "25 - 49" 3 "50 - 99" 0 "100 or more"
		label values sworn sworn
		tab sworn

		replace sworn = 3 if id == 592 // agency has 84 sworn
		replace sworn = 3 if id == 497 // agency has 65 sworn
		tab sworn, m

	* Global Outcome: support law requiring release of BWC footage
		gen BWClaw = 6 - q12
		sum BWClaw
			 					 
	* Experimental Outcome: anticipated media coverage of the randomized OIS
		factor q11*, mine(1)
		predict OISmedia_factor // for supplemental analysis
		alpha q11*
		egen OISmedia = rmean(q11*)
		sum OISmedia, detail
					 					 
	* Experimental Outcome: communication w/public following randomized OIS
		clonevar Justified = q10a
		clonevar ReleaseVid = q10b
		clonevar ReleaseInfo = q10c
		clonevar ReleaseName = q10d
		clonevar UseSocMedia = q10e
		clonevar MediaState = q10f
		clonevar MeetFamily = q10g

		factor q10b q10c q10e q10f q10g, mine(1)
		predict OIStrans_factor // for supplemental analysis
		alpha q10b q10c q10e q10f q10g
		egen OIStrans = rmean(q10b q10c q10e q10f q10g)
		sum OIStrans, detail

	* Independent Variables: Experimental manipulations					 
		gen SuspectBlack = .
		replace SuspectBlack = 0 if version >=1 & version <= 4
		replace SuspectBlack = 1 if version >=5 & version <= 8
		label define SuspectBlack 0 "White Suspect" 1 "Black Suspect"					 
		label values SuspectBlack SuspectBlack
		tab SuspectBlack

		gen SuspectUnarmed = .
		replace SuspectUnarmed = 1 if version == 3 | version == 4 | version == 7 | version == 8
		replace SuspectUnarmed = 0 if version == 1 | version == 2 | version == 5 | version == 6
		label define SuspectUnarmed 0 "Handgun" 1 "Cellphone"
		label values SuspectUnarmed SuspectUnarmed
		tab SuspectUnarmed
		

* CREATE SAMPLING WEIGHTS 
	recode sworn (0 =3) (1=0) (2=1) (3=2), gen (SwornR)
	label define SwornR 0 "0-24" 1 "25-49" 2 "50-99" 3 "100+"
	label values SwornR SwornR
	tab SwornR
	
	/* For each stratum, divide [% of sample frame] by [% of sample] to generate weight variable:

		* 0-24:  74.26/22.41 = 3.3137
		* 25-49: 13.38/25.86 = 0.5174
		* 50-99:  6.93/25.26 = 0.2743
		* 100+:   5.43/26.47 = 0.2051 */

	gen fweight = .
	replace fweight = 3.3137 if SwornR == 0
	replace fweight = .5174 if SwornR == 1
	replace fweight = .2743 if SwornR == 2
	replace fweight = .2051 if SwornR == 3

	tab fweight SwornR 
	svyset [pw= fweight]
	svy: proportion SwornR


* ANALYSES 

	* Figure 1: Support for BWC Legislation
		svy: proportion BWClaw if SwornR == 0 & chief == 1
		svy: proportion BWClaw if SwornR == 1 & chief == 1
		svy: proportion BWClaw if SwornR == 2 & chief == 1
		svy: proportion BWClaw if SwornR == 3 & chief == 1

		tab BWClaw SwornR if chief == 1, col chi

	* Table 1: Regression Models

	* Anticipated Media Coverage (Models 1, 4, 7, 10)
		regress OISmedia SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 0
		ritest SuspectBlack _b[SuspectBlack], reps (1000) seed (1983): regress OISmedia SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 0
		ritest SuspectUnarmed _b[SuspectUnarmed], reps (1000) seed (1983): regress OISmedia SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 0

		regress OISmedia SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 1
		ritest SuspectBlack _b[SuspectBlack], reps (1000) seed (1983): regress OISmedia SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 1
		ritest SuspectUnarmed _b[SuspectUnarmed], reps (1000) seed (1983): regress OISmedia SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 1

		regress OISmedia SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 2
		ritest SuspectBlack _b[SuspectBlack], reps (1000) seed (1983): regress OISmedia SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 2
		ritest SuspectUnarmed _b[SuspectUnarmed], reps (1000) seed (1983): regress OISmedia SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 2

		regress OISmedia SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 3
		ritest SuspectBlack _b[SuspectBlack], reps (1000) seed (1983): regress OISmedia SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 3
		ritest SuspectUnarmed _b[SuspectUnarmed], reps (1000) seed (1983): regress OISmedia SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 3


	* State Justified (Models 2, 5, 8, 11)
		regress Justified SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 0
		ritest SuspectBlack _b[SuspectBlack], reps (1000) seed (1983): regress Justified SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 0
		ritest SuspectUnarmed _b[SuspectUnarmed], reps (1000) seed (1983): regress Justified SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 0

		regress Justified SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 1
		ritest SuspectBlack _b[SuspectBlack], reps (1000) seed (1983): regress Justified SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 1
		ritest SuspectUnarmed _b[SuspectUnarmed], reps (1000) seed (1983): regress Justified SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 1

		regress Justified SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 2
		ritest SuspectBlack _b[SuspectBlack], reps (1000) seed (1983): regress Justified SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 2
		ritest SuspectUnarmed _b[SuspectUnarmed], reps (1000) seed (1983): regress Justified SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 2

		regress Justified SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 3
		ritest SuspectBlack _b[SuspectBlack], reps (1000) seed (1983): regress Justified SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 3
		ritest SuspectUnarmed _b[SuspectUnarmed], reps (1000) seed (1983): regress Justified SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 3


	* Additional Communication (Models 3, 6, 9, 12)
		regress OIStrans SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 0
		ritest SuspectBlack _b[SuspectBlack], reps (1000) seed (1983): regress OIStrans SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 0
		ritest SuspectUnarmed _b[SuspectUnarmed], reps (1000) seed (1983): regress OIStrans SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 0

		regress OIStrans SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 1
		ritest SuspectBlack _b[SuspectBlack], reps (1000) seed (1983): regress OIStrans SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 1
		ritest SuspectUnarmed _b[SuspectUnarmed], reps (1000) seed (1983): regress OIStrans SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 1

		regress OIStrans SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 2
		ritest SuspectBlack _b[SuspectBlack], reps (1000) seed (1983): regress OIStrans SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 2
		ritest SuspectUnarmed _b[SuspectUnarmed], reps (1000) seed (1983): regress OIStrans SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 2

		regress OIStrans SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 3
		ritest SuspectBlack _b[SuspectBlack], reps (1000) seed (1983): regress OIStrans SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 3
		ritest SuspectUnarmed _b[SuspectUnarmed], reps (1000) seed (1983): regress OIStrans SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 3

		
    * Select Model for Agency Size X Unarmed on Anticipated Media (Adjusted R2 higher, AIC lower, and BIC lower for continuous interaction)
		regress OISmedia SuspectBlack SuspectUnarmed##c.SwornR if chief == 1
		estimates store model1
		regress OISmedia SuspectBlack SuspectUnarmed##i.SwornR if chief == 1
		estimates store model2
		lrtest model1 model2,stats
	
	* Interaction of Agency Size X Unarmed on Anticipated Media
		regress OISmedia SuspectBlack SuspectUnarmed##c.SwornR if chief == 1
		margins SuspectUnarmed, at (SwornR=(0(1)3))
	
	* Figure 2
		marginsplot, title("Predictive Margins of {it:Unarmed Suspect} with 95% CIs", size(medsmall)) ///
					 ytitle("Anticipated Hostility of Media Coverage", size(small)) ///
					 xtitle("Number of Sworn Officers", size(small)) ///
					 scheme(plottig) legend(pos(6) rows(1)) name(fig1, replace)
			 
	* Create new variable reflecting product term so that we can run RITEST
		gen UnarmedAgency = SuspectUnarmed * SwornR
		tab UnarmedAgency

		ritest SuspectBlack _b[SuspectBlack], reps (1000) seed (1983): regress OISmedia SuspectBlack SuspectUnarmed##c.SwornR if chief == 1
		ritest UnarmedAgency _b[UnarmedAgency], reps (1000) seed (1983): regress OISmedia SuspectBlack UnarmedAgency if chief == 1

		
    * Select Model for Interaction of Agency Size X Unarmed on Justified (Adjusted R2 higher, AIC lower for factor-variable interaction)
		regress Justified SuspectBlack SuspectUnarmed##c.SwornR if chief == 1
		estimates store model1
		regress Justified SuspectBlack SuspectUnarmed##i.SwornR if chief == 1
		estimates store model2
		lrtest model1 model2,stats
	
	* Interaction of Agency Size X Unarmed on Justified
		regress Justified SuspectBlack SuspectUnarmed##i.SwornR if chief == 1
		margins SuspectUnarmed, at(SwornR=(0(1)3))
	
	* Figure 3
		marginsplot, title("Predictive Margins of {it:Unarmed Suspect} with 95% CIs", size(medsmall)) ///
					 ytitle("Importance of Stating Publicly that Shooting was Justified", size(small)) ///
					 xtitle("Number of Sworn Officers", size(small)) ///
					 scheme(plottig) legend(pos(6) rows(1)) name (fig2, replace)
					 
		ritest SuspectBlack _b[SuspectBlack], reps (1000) seed (1983): regress Justified SuspectBlack SuspectUnarmed##i.SwornR if chief == 1
		ritest UnarmedAgency _b[UnarmedAgency], reps (1000) seed (1983): regress Justified SuspectBlack UnarmedAgency if chief == 1

		graph combine fig1 fig2, scheme(plottig) ycommon
		

********************************************************************************************************

* SUPPLEMENTAL APPENDICES

	* Tables A1-A3: Demographics, BWC Usage, and Treatment Balance
		gen male = .
		replace male = 0 if q19 == 0 & mode == 1
		replace male = 1 if q19 == 1 & mode == 1
		replace male = 1 if q19 == 1 & mode == 0
		replace male = 0 if q19 == 2 & mode == 0
		tab male
		
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

		gen masters = . 
		replace masters = 1 if q23 == 6 | q23 == 7 // MA/JD or PhD
		replace masters = 0 if q23 >= 1 & q23 <= 5 // less than MA/JD
		tab masters
		
		gen BWC = . // Does your agency currently use BWCs? 
			replace BWC = 0 if q18 == 0 & mode == 1
			replace BWC = 1 if q18 == 1 & mode == 1
			replace BWC = 1 if q18 == 1 & mode == 0
			replace BWC = 0 if q18 == 2 & mode == 0
			tab BWC
			
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
		
	* Check for balance of demographic variables across treatment groups
		tab SuspectBlack male, col
		tab SuspectUnarmed male, col
			ttest SuspectBlack, by(male)
			ttest SuspectUnarmed, by(male)
		
		tab SuspectBlack white, col
		tab SuspectUnarmed white, col
			ttest SuspectBlack, by(white)
			ttest SuspectUnarmed, by(white)
		
		tab SuspectBlack masters, col
		tab SuspectUnarmed masters, col
			ttest SuspectBlack, by(masters)
			ttest SuspectUnarmed, by(masters)
			
		tab SuspectBlack BWC, col
		tab SuspectUnarmed BWC, col
			ttest SuspectBlack, by(BWC)
			ttest SuspectUnarmed, by(BWC)
				
		sum LEyrs if SuspectBlack==1
		sum LEyrs if SuspectBlack==0
		sum LEyrs if SuspectUnarmed==1
		sum LEyrs if SuspectUnarmed==0
			ttest LEyrs, by(SuspectBlack)
			ttest LEyrs, by(SuspectUnarmed)
			
		
	* Table B1: Measurement invariance for Anticipated Media and Additional Communication outcomes
		/* Can't get  CFA model to identify due to too few pieces of information.
		   So, running factor analyses separately on each stratum. This will at least give a sense
		   of whether the items hang together similarly across groups. */
		
		factor q10b q10c q10e q10f q10g if SwornR == 0, mine(1)
		factor q10b q10c q10e q10f q10g if SwornR == 1, mine(1)
		factor q10b q10c q10e q10f q10g if SwornR == 2, mine(1)
		factor q10b q10c q10e q10f q10g if SwornR == 3, mine(1)
		
		factor q11* if SwornR == 0, mine(1)
		factor q11* if SwornR == 1, mine(1)
		factor q11* if SwornR == 2, mine(1)
		factor q11* if SwornR == 3, mine(1)
		
		alpha q10b q10c q10e q10f q10g if SwornR == 0
		alpha q10b q10c q10e q10f q10g if SwornR == 1
		alpha q10b q10c q10e q10f q10g if SwornR == 2
		alpha q10b q10c q10e q10f q10g if SwornR == 3
		
		alpha q11* if SwornR == 0
		alpha q11* if SwornR == 1
		alpha q11* if SwornR == 2
		alpha q11* if SwornR == 3


	* Table C1: Using weighted factor scores instead of averaged scales
		regress OISmedia_factor SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 0
		regress OISmedia_factor SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 1
		regress OISmedia_factor SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 2
		regress OISmedia_factor SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 3
		
		regress OIStrans_factor SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 0
		regress OIStrans_factor SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 1
		regress OIStrans_factor SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 2
		regress OIStrans_factor SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 3
		
		
	* Table D1: OLogit instead of OLS for the State Justified outcome
		ologit Justified SuspectBlack SuspectUnarmed if chief == 1 & SwornR !=.
		ologit Justified SuspectBlack SuspectUnarmed [pweight = fweight] if chief == 1 & SwornR !=.
		ologit Justified SuspectBlack SuspectUnarmed i.SwornR if chief == 1 & SwornR !=.
		ologit Justified SuspectBlack SuspectUnarmed i.SwornR [pweight = fweight] if chief == 1 & SwornR !=.
		
		ologit Justified SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 0
		ologit Justified SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 1
		ologit Justified SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 2
		ologit Justified SuspectBlack SuspectUnarmed if chief == 1 & SwornR == 3
		
		ologit Justified SuspectBlack SuspectUnarmed##i.SwornR if chief == 1
		margins SuspectUnarmed, at(SwornR=(0(1)3))
		
		marginsplot, title("Predictive Margins of {it:Unarmed Suspect} with 95% CIs", size(medsmall)) ///
			ytitle("Importance of Stating Publicly that Shooting was Justified", size(small)) ///
			xtitle("Number of Sworn Officers", size(small)) ///
			scheme(plottig) legend(pos(6) rows(1)) name (fig2, replace)
	
	
	* Tables E1-E2: Include interaction terms for Unarmed*Population & Unarmed*Violent Crime in Figures 2 & 3
		* Average each agency's population as reported to the UCR from 2014-16
			egen AvPop = rmean(ucrpop*)
			gen ln_pop = ln(AvPop)+1 // transformation to reduce skew & kurtosis
		
		* Calculate average violent crime rates from 2014-16
			gen vrate14 = (vcrime14/ucrpop14)*100000
			gen vrate15 = (vcrime15/ucrpop15)*100000
			gen vrate16 = (vcrime16/ucrpop16)*100000
			egen AvVrate = rmean(vrate*)
			gen ln_vrate = ln(AvVrate)+1 // reduce skew
			
		* E1: Interactions of Population*Unarmed & Population*Violent Crime Rate on Anticipated Media
		* NOTE: Our sample size is reduced to 397 due to missing UCR data!	
			regress OISmedia SuspectBlack SuspectUnarmed##c.SwornR SuspectUnarmed##c.ln_pop SuspectUnarmed##c.ln_vrate if chief == 1
			di %6.3f e(F)
		* E2: Interactions of Population*Unarmed & Population*Violent Crime Rate  on Justified
			regress Justified SuspectBlack SuspectUnarmed##i.SwornR SuspectUnarmed##c.ln_pop SuspectUnarmed##c.ln_vrate if chief == 1
			di %6.3f e(F)
