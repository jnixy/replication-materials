/********************************************************************************************************
- Nix, Pickett, & Mitchell (2019)
- "Compliance, Noncompliance, and the In-Between"
- Journal of Experimental Criminology, 15(4), 611-639
- Code written 5/18/2018
- Last updated 2/27/2019
- All analyses performed in Stata v15
********************************************************************************************************/

/* Survey of Anonymous Police Department, administered January 15 - February 3 via SurveyMonkey */

* Call up the data

use "~\demeanor_experiments.dta" 

*******************************************************************************
                /********** CLEANING THE DATA **********/
*******************************************************************************

* Combine the variables that were split up into groups due to a restriction put in place by SurveyMonkey */

	gen exp1 =.
	replace exp1 = 1 if q0006_question == 1
	replace exp1 = 2 if q0006_question == 2
	replace exp1 = 3 if q0006_question == 3
	replace exp1 = 4 if q0006_question == 4
	replace exp1 = 5 if q0006_question == 5
	replace exp1 = 6 if q0006_question == 6
	replace exp1 = 7 if q0006_question == 7
	replace exp1 = 8 if q0006_question == 8
	replace exp1 = 9 if q0006_question == 9
	replace exp1 = 10 if q0006_question == 10
	replace exp1 = 11 if q0006_question == 11
	replace exp1 = 12 if q0006_question == 12
	replace exp1 = 13 if q0013_question == 1
	replace exp1 = 14 if q0013_question == 2
	replace exp1 = 15 if q0013_question == 3
	replace exp1 = 16 if q0013_question == 4
	replace exp1 = 17 if q0013_question == 5
	replace exp1 = 18 if q0013_question == 6
	replace exp1 = 19 if q0013_question == 7
	replace exp1 = 20 if q0013_question == 8
	replace exp1 = 21 if q0013_question == 9
	replace exp1 = 22 if q0013_question == 10
	replace exp1 = 23 if q0013_question == 11
	replace exp1 = 24 if q0013_question == 12

	clonevar Q6 = q0006
	replace  Q6 = q0013 if q0006 ==. & q0013 !=.

	clonevar Q7 = q0007
	replace  Q7 = q0014 if q0007 ==. & q0014 !=.

	clonevar Q8a = q0008_0001
	clonevar Q8b = q0008_0002
	clonevar Q8c = q0008_0003
	replace  Q8a = q0015_0001 if q0008_0001 ==. & q0015_0001 !=.
	replace  Q8b = q0015_0002 if q0008_0002 ==. & q0015_0002 !=.
	replace  Q8c = q0015_0003 if q0008_0003 ==. & q0015_0003 !=.

	clonevar Q9 = q0009
	replace  Q9 = q0016 if q0009 ==. & q0016 !=.

* Drop 5 blank surveys
	drop if q0001 == .


* CREATE VARIABLES

* Experiment 1: Littering 
	clonevar SuspectBehavior = q0030_question
	recode SuspectBehavior (3=0) (2=2) (1=1)
	label define SuspectBehavior 0 "Compliant" 1 "Bad Attitude" 2 "Noncompliant"
	label values SuspectBehavior SuspectBehavior

	* DV: Suspicion
		clonevar suspicious1 = q0030

	* DV: Negative Emotions
		clonevar annoy1 = q0031_0001
		clonevar frust1 = q0031_0002 
		clonevar anger1 = q0031_0003

		factor anger1 annoy1 frust1, mine(1)
		alpha anger1 annoy1 frust1
		egen negemo1 = rmean(anger1 annoy1 frust1) 

	* DV: Fear
		gen fear1 = 6 - q0032

* Experiment 2: Speeding Violation
	clonevar SuspectBehavior2 = q0023_question
	recode SuspectBehavior2 (3=0) (2=2) (1=1)
	label define SuspectBehavior2 0 "Compliant" 1 "Bad Attitude" 2 "Noncompliant"
	label values SuspectBehavior2 SuspectBehavior2

	* DV: Suspicion
		clonevar suspicious2 = q0023

	* DV: Negative emotions
		clonevar annoy2 = q0024_0001 
		clonevar frust2 = q0024_0002 
		clonevar anger2 = q0024_0003 

		factor anger2 annoy2 frust2, mine(1)
		alpha anger2 annoy2 frust2
		egen negemo2 = rmean(anger2 annoy2 frust2)

	* DV: Fear
		gen fear2 = 6 - q0025

* Experiment 3: Suspicious Person 
	recode exp1 (1/6 13/18= 0) (7/12 19/24 = 1), gen(SuspectBlack)
	label define SuspectBlack 0 "White Suspect" 1 "Black Suspect"
	label values SuspectBlack SuspectBlack

	recode exp1 (1/12 = 0) (13/24 = 1), gen (SuspectMale)
	label define SuspectMale 0 "Female Suspect" 1 "Male Suspect"
	label values SuspectMale SuspectMale

	recode exp1 (1 3 5 7 9 11 13 15 17 19 21 23 = 0) (2 4 6 8 10 12 14 16 18 20 22 24 = 1), gen(HighCrimeHood)
	label define HighCrimeHood 0 "Low Crime Neighborhood" 1 "High Crime Neighborhood"
	label values HighCrimeHood HighCrimeHood

	recode exp1 (1 2 7 8 13 14 19 20 = 0) (3 4 9 10 15 16 21 22 = 1) (5 6 11 12 17 18 23 24 = 2), gen(SuspectBehavior3)
	label define SuspectBehavior3 0 "Compliant" 1 "Bad Attitude" 2 "Noncompliant"
	label values SuspectBehavior3 SuspectBehavior3

	* DV: Perceived Danger
		gen violent = 6 - Q6

	* DV: Suspicion
		clonevar suspicious3 = Q7

	* DV: Negative Emotions
		clonevar annoy3 = Q8a
		clonevar frust3 = Q8b 
		clonevar anger3 = Q8c 

		factor anger3 annoy3 frust3, mine(1)
		alpha anger3 annoy3 frust3
		egen negemo3 = rmean(anger3 annoy3 frust3)

	* DV: Fear
		gen fear3 = 6 - Q9



***** ANALYSES *****

* Experiment 1
	regress suspicious1 i.SuspectBehavior
	ritest SuspectBehavior _b[1.SuspectBehavior]  _b[2.SuspectBehavior], reps (1000): regress suspicious1 i.SuspectBehavior

	regress negemo1 i.SuspectBehavior
	ritest SuspectBehavior _b[1.SuspectBehavior]  _b[2.SuspectBehavior], reps (1000): regress negemo1 i.SuspectBehavior

	regress fear1 i.SuspectBehavior
	ritest SuspectBehavior _b[1.SuspectBehavior]  _b[2.SuspectBehavior], reps (1000): regress fear1 i.SuspectBehavior

* Experiment 2
	regress suspicious2 i.SuspectBehavior2
	ritest SuspectBehavior2 _b[1.SuspectBehavior2]  _b[2.SuspectBehavior2], reps (1000): regress suspicious2 i.SuspectBehavior2

	regress negemo2 i.SuspectBehavior2
	ritest SuspectBehavior2 _b[1.SuspectBehavior2]  _b[2.SuspectBehavior2], reps (1000): regress negemo2 i.SuspectBehavior2

	regress fear2 i.SuspectBehavior2
	ritest SuspectBehavior2 _b[1.SuspectBehavior2]  _b[2.SuspectBehavior2], reps (1000): regress fear2 i.SuspectBehavior2

* Experiment 3
	regress suspicious3 i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood
	ritest SuspectBehavior3 _b[1.SuspectBehavior3]  _b[2.SuspectBehavior3], reps (1000): regress suspicious3 i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood
	ritest SuspectBlack  _b[SuspectBlack], reps (1000): regress suspicious3 i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood
	ritest SuspectMale  _b[SuspectMale], reps (1000): regress suspicious3 i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood
	ritest HighCrimeHood  _b[HighCrimeHood], reps (1000): regress suspicious3 i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood

	regress violent i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood
	ritest SuspectBehavior3 _b[1.SuspectBehavior3]  _b[2.SuspectBehavior3], reps (1000): regress violent i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood
	ritest SuspectBlack  _b[SuspectBlack], reps (1000): regress violent i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood
	ritest SuspectMale  _b[SuspectMale], reps (1000): regress violent i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood
	ritest HighCrimeHood  _b[HighCrimeHood], reps (1000): regress violent i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood

	regress negemo3 i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood
	ritest SuspectBehavior3 _b[1.SuspectBehavior3]  _b[2.SuspectBehavior3], reps (1000): regress negemo3 i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood
	ritest SuspectBlack  _b[SuspectBlack], reps (1000): regress negemo3 i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood
	ritest SuspectMale  _b[SuspectMale], reps (1000): regress negemo3 i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood
	ritest HighCrimeHood  _b[HighCrimeHood], reps (1000): regress negemo3 i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood

	regress fear3 i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood
	ritest SuspectBehavior3 _b[1.SuspectBehavior3]  _b[2.SuspectBehavior3], reps (1000): regress fear3 i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood
	ritest SuspectBlack  _b[SuspectBlack], reps (1000): regress fear3 i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood
	ritest SuspectMale  _b[SuspectMale], reps (1000): regress fear3 i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood
	ritest HighCrimeHood  _b[HighCrimeHood], reps (1000): regress fear3 i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood



********************************************************************************
               /********** ROBUSTNESS CHECKS **********/
********************************************************************************

* RUNNING RANDOMIZATION INFERENCE SEPERATELY

* Experiment 1
	ritest SuspectBehavior _b[SuspectBehavior], reps (1000) seed (1983) : regress suspicious1 SuspectBehavior if SuspectBehavior !=2 
	ritest SuspectBehavior _b[SuspectBehavior], reps (1000) seed (1983) : regress suspicious1 SuspectBehavior if SuspectBehavior !=1
	ritest SuspectBehavior _b[SuspectBehavior], reps (1000) seed (1983) : regress negemo1 SuspectBehavior if SuspectBehavior !=2 
	ritest SuspectBehavior _b[SuspectBehavior], reps (1000) seed (1983) : regress negemo1 SuspectBehavior if SuspectBehavior !=1
	ritest SuspectBehavior _b[SuspectBehavior], reps (1000) seed (1983) : regress fear1 SuspectBehavior if SuspectBehavior !=2 
	ritest SuspectBehavior _b[SuspectBehavior], reps (1000) seed (1983) : regress fear1 SuspectBehavior if SuspectBehavior !=1

* Experiment 2
	ritest SuspectBehavior2 _b[SuspectBehavior2], reps (1000) seed (1983) : regress suspicious2 SuspectBehavior2 if SuspectBehavior2 !=2 
	ritest SuspectBehavior2 _b[SuspectBehavior2], reps (1000) seed (1983) : regress suspicious2 SuspectBehavior2 if SuspectBehavior2 !=1 
	ritest SuspectBehavior2 _b[SuspectBehavior2], reps (1000) seed (1983) : regress negemo2 SuspectBehavior2 if SuspectBehavior2 !=2 
	ritest SuspectBehavior2 _b[SuspectBehavior2], reps (1000) seed (1983) : regress negemo2 SuspectBehavior2 if SuspectBehavior2 !=1
	ritest SuspectBehavior2 _b[SuspectBehavior2], reps (1000) seed (1983) : regress fear2 SuspectBehavior2 if SuspectBehavior2 !=2 
	ritest SuspectBehavior2 _b[SuspectBehavior2], reps (1000) seed (1983) : regress fear2 SuspectBehavior2 if SuspectBehavior2 !=1

* Experiment 3
	ritest SuspectBehavior3 _b[SuspectBehavior3], reps (1000) seed (1983) : regress suspicious3 SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood if SuspectBehavior3 !=2
	ritest SuspectBehavior3 _b[SuspectBehavior3], reps (1000) seed (1983) : regress suspicious3 SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood if SuspectBehavior3 !=1
	ritest SuspectBehavior3 _b[SuspectBehavior3], reps (1000) seed (1983) : regress violent SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood if SuspectBehavior3 !=2
	ritest SuspectBehavior3 _b[SuspectBehavior3], reps (1000) seed (1983) : regress violent SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood if SuspectBehavior3 !=1
	ritest SuspectBehavior3 _b[SuspectBehavior3], reps (1000) seed (1983) : regress negemo3 SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood if SuspectBehavior3 !=2
	ritest SuspectBehavior3 _b[SuspectBehavior3], reps (1000) seed (1983) : regress negemo3 SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood if SuspectBehavior3 !=1
	ritest SuspectBehavior3 _b[SuspectBehavior3], reps (1000) seed (1983) : regress fear3 SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood if SuspectBehavior3 !=2
	ritest SuspectBehavior3 _b[SuspectBehavior3], reps (1000) seed (1983) : regress fear3 SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood if SuspectBehavior3 !=1


* SAME MODELS, EXCLUDING CHIEF, ASST CHIEF, COMMANDERS(8), AND LTs(43)

	recode q0042 (6 = 0) (4/5 = 1) (1/3 = 2), gen(Rank)
	label define Rank 0 "0. Police Officer" 1 "1. Front-line Supervisor" 2 "2. Command Staff"
	label values Rank Rank

* Experiment 1
	regress suspicious1 i.SuspectBehavior if Rank!=2, robust level(98.3)
	regress     negemo1 i.SuspectBehavior if Rank!=2, robust level(98.3)
	regress       fear1 i.SuspectBehavior if Rank!=2, robust level(98.3)

* Experiment 2
	regress suspicious2 i.SuspectBehavior2 if Rank!=2, robust level(98.3)
	regress     negemo2 i.SuspectBehavior2 if Rank!=2, robust level(98.3)
	regress       fear2 i.SuspectBehavior2 if Rank!=2, robust level(98.3)

* Experiment 3
	regress suspicious3 i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood if Rank!=2, robust level(98.3)
	regress     violent i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood if Rank!=2, robust level(98.3)
	regress     negemo3 i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood if Rank!=2, robust level(98.3)
	regress       fear3 i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood if Rank!=2, robust level(98.3)



/* BINARY LOGITS WITH MEDIAN SPLITS */

	sum suspicious1, detail
	gen splitsus1 = cond(missing(suspicious1), ., (suspicious1 >=r(p50)))
	sum suspicious2, detail
	gen splitsus2 = cond(missing(suspicious2), ., (suspicious2 >=r(p50)))
	sum suspicious3, detail
	gen splitsus3 = cond(missing(suspicious3), ., (suspicious3 >=r(p50)))

	sum negemo1, detail
	gen splitemo1 = cond(missing(negemo1), ., (negemo1 >=r(p50)))
	sum negemo2, detail
	gen splitemo2 = cond(missing(negemo2), ., (negemo2 >=r(p50)))
	sum negemo3, detail
	gen splitemo3 = cond(missing(negemo3), ., (negemo3 >=r(p50)))

	sum fear1, detail
	gen splitfear1 = cond(missing(fear1), ., (fear1 >=r(p50)))
	sum fear2, detail
	gen splitfear2 = cond(missing(fear2), ., (fear2 >=r(p50)))
	sum fear3, detail
	gen splitfear3 = cond(missing(fear3), ., (fear3 >=r(p50)))

	sum violent, detail
	gen splitvio = cond(missing(violent), ., (violent >=r(p50)))

	logit  splitsus1 i.SuspectBehavior
	logit  splitemo1 i.SuspectBehavior
	logit splitfear1 i.SuspectBehavior

	logit  splitsus2 i.SuspectBehavior2
	logit  splitemo2 i.SuspectBehavior2
	logit splitfear2 i.SuspectBehavior2

	logit  splitsus3 i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood
	logit   splitvio i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood
	logit  splitemo3 i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood
	logit splitfear3 i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood


* KW/DUNN, ANOVA, AND OLOGITS

* Experiment #1
	dunntest suspicious1, by(SuspectBehavior) nolabel ma(bonferroni)
	oneway negemo1 SuspectBehavior, tabulate
	pwmean negemo1, over(SuspectBehavior) mcompare(bonferroni) effects
	dunntest fear1, by(SuspectBehavior) nolabel ma(bonferroni)

* Experiment #2
	dunntest suspicious2, by(SuspectBehavior2) nolabel ma(bonferroni)
	oneway negemo2 SuspectBehavior2, tabulate
	pwmean negemo2, over(SuspectBehavior2) mcompare(bonferroni) effects
	dunntest fear2, by(SuspectBehavior2) nolabel ma(bonferroni)

* Experiment #3
	ologit suspicious3 i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood, or level(98.3)
	ologit violent i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood, or level(98.3)
	regress negemo3 i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood, level (98.3)
	ologit fear3 i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood, or level(98.3)


/* BOOTSTRAPPED STANDARD ERRORS */

* Experiment 1
	regress suspicious1 i.SuspectBehavior, vce(bootstrap, reps(200)) level(98.3)
	regress     negemo1 i.SuspectBehavior, vce(bootstrap, reps(200)) level(98.3)
	regress       fear1 i.SuspectBehavior, vce(bootstrap, reps(200)) level(98.3)

* Experiment 2
	regress suspicious2 i.SuspectBehavior2, vce(bootstrap, reps(200)) level(98.3)
	regress     negemo2 i.SuspectBehavior2, vce(bootstrap, reps(200)) level(98.3)
	regress       fear2 i.SuspectBehavior2, vce(bootstrap, reps(200)) level(98.3)

* Experiment 3
	regress suspicious3 i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood, vce(bootstrap, reps(200)) level(98.3)
	regress     violent i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood, vce(bootstrap, reps(200)) level(98.3)
	regress     negemo3 i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood, vce(bootstrap, reps(200)) level(98.3)
	regress       fear3 i.SuspectBehavior3 SuspectBlack SuspectMale HighCrimeHood, vce(bootstrap, reps(200)) level(98.3)


/* ANOVAs failed the homogeneity of variance assumption, so running regression 
   with robust standard errors to see if the results are the same */
	regress negemo1 i.SuspectBehavior, robust level(98.3)
	regress negemo2 i.SuspectBehavior2, robust level(98.3)


* Dichotomize each variable for use in Figure 1 
	recode suspicious* (1/3 = 0) (4/6 = 1)
	label variable suspicious1 "Suspicious"
	label variable suspicious2 "Suspicious"
	label variable suspicious3 "Suspicious"

	recode anger*  (1 = 0) (2/4 = 1)
	label variable anger1 "Angry"
	label variable anger2 "Angry"
	label variable anger3 "Angry"

	recode annoy*  (1 = 0) (2/4 = 1)
	label variable annoy1 "Annoyed"
	label variable annoy2 "Annoyed"
	label variable annoy3 "Annoyed"

	recode frust*  (1 = 0) (2/4 = 1)
	label variable frust1 "Frustrated"
	label variable frust2 "Frustrated"
	label variable frust3 "Frustrated"

	recode fear*   (1/3 = 0) (4/5 = 1)
	label variable fear1 "Fear"
	label variable fear2 "Fear"
	label variable fear3 "Fear"

	recode violent (1/3 = 0) (4/5 = 1)
	label variable violent "Perceived Danger"

/* Row 1 - Experiment #1 */
	tab suspicious1 SuspectBehavior, nolabel col
	tab anger1 SuspectBehavior, nolabel col
	tab annoy1 SuspectBehavior, nolabel col
	tab frust1 SuspectBehavior, nolabel col
	tab fear1 SuspectBehavior, nolabel col

/* Row 2 - Experiment #2 */
	tab suspicious2 SuspectBehavior2, nolabel col
	tab anger2 SuspectBehavior2, nolabel col
	tab annoy2 SuspectBehavior2, nolabel col
	tab frust2 SuspectBehavior2, nolabel col
	tab fear2 SuspectBehavior2, nolabel col

/* Row 3 - Experiment #3 */
	tab suspicious3 SuspectBehavior3, nolabel col
	tab violent SuspectBehavior3, nolabel col
	tab anger3 SuspectBehavior3, nolabel col
	tab annoy3 SuspectBehavior3, nolabel col
	tab frust3 SuspectBehavior3, nolabel col
	tab fear3 SuspectBehavior3, nolabel col




/********** Create Figure 1 **********/
graph bar (mean) suspicious1 anger1 annoy1 frust1 fear1 if SuspectBehavior ==0, ///
		  ytitle("Mean", size(vsmall)) yscale(range(0(.1)1.0)) ylabel(0(.2)1.0, labsize(tiny) nogrid) ///
		  title("Compliant", size(small)) bargap(50) showyvars ///
		  yvaroptions(relabel(1 "Suspicious" 2 "Angry" 3 "Annoyed" 4 "Frustrated" 5 "Fearful") label(labs(vsmall) angle(35))) ///
		  blabel(total, pos(outside) format(%4.2f) size(vsmall) c(gs0)) ///
		  legend(off) ///
		  scheme(plottig) name(exp1a, replace)
		  
graph bar (mean) suspicious1 anger1 annoy1 frust1 fear1 if SuspectBehavior ==1, ///
		  ytitle("Mean", size(vsmall)) yscale(range(0(.1)1.0)) ylabel(0(.2)1.0, labsize(tiny) nogrid) ///
		  title("Bad Attitude", size(small)) bargap(50) showyvars ///
		  yvaroptions(relabel(1 "Suspicious" 2 "Angry" 3 "Annoyed" 4 "Frustrated" 5 "Fearful") label(labs(vsmall) angle(35))) ///
		  blabel(total, pos(outside) format(%4.2f) size(vsmall) c(gs0)) ///
		  legend(off) ///
		  scheme(plottig) name(exp1b, replace)
		  
graph bar (mean) suspicious1 anger1 annoy1 frust1 fear1 if SuspectBehavior ==2, ///
		  ytitle("Mean", size(vsmall)) yscale(range(0(.1)1.0)) ylabel(0(.2)1.0, labsize(tiny) nogrid) ///
		  title("Noncompliant", size(small)) bargap(50) showyvars ///
		  yvaroptions(relabel(1 "Suspicious" 2 "Angry" 3 "Annoyed" 4 "Frustrated" 5 "Fearful") label(labs(vsmall) angle(35))) ///
		  blabel(total, pos(outside) format(%4.2f) size(vsmall) c(gs0)) ///
		  legend(off) ///
		  scheme(plottig) name(exp1c, replace)
		  
graph bar (mean) suspicious2 anger2 annoy2 frust2 fear2 if SuspectBehavior2 ==0, ///
		  ytitle("Mean", size(vsmall)) yscale(range(0(.1)1.0)) ylabel(0(.2)1.0, labsize(tiny) nogrid) ///
		  title("Compliant", size(small)) bargap(50) showyvars  ///
		  yvaroptions(relabel(1 "Suspicious" 2 "Angry" 3 "Annoyed" 4 "Frustrated" 5 "Fearful") label(labs(vsmall) angle(35))) ///
		  blabel(total, pos(outside) format(%4.2f) size(vsmall) c(gs0)) ///
		  legend(off) ///
		  scheme(plottig) name(exp2a, replace)
		  
graph bar (mean) suspicious2 anger2 annoy2 frust2 fear2 if SuspectBehavior2 ==1, ///
		  ytitle("Mean", size(vsmall)) yscale(range(0(.1)1.0)) ylabel(0(.2)1.0, labsize(tiny) nogrid) ///
		  title("Bad Attitude", size(small)) bargap(50) showyvars ///
		  yvaroptions(relabel(1 "Suspicious" 2 "Angry" 3 "Annoyed" 4 "Frustrated" 5 "Fearful") label(labs(vsmall) angle(35))) ///
		  blabel(total, pos(outside) format(%4.2f) size(vsmall) c(gs0)) ///
		  legend(off) ///
		  scheme(plottig) name(exp2b, replace)
		  
graph bar (mean) suspicious2 anger2 annoy2 frust2 fear2 if SuspectBehavior2 ==2, ///
		  ytitle("Mean", size(vsmall)) yscale(range(0(.1)1.0)) ylabel(0(.2)1.0, labsize(tiny) nogrid) ///
		  title("Noncompliant", size(small)) bargap(50) showyvars ///
		  yvaroptions(relabel(1 "Suspicious" 2 "Angry" 3 "Annoyed" 4 "Frustrated" 5 "Fearful") label(labs(vsmall) angle(35))) ///
		  blabel(total, pos(outside) format(%4.2f) size(vsmall) c(gs0)) ///
		  legend(off) ///
		  scheme(plottig) name(exp2c, replace)
		  
graph bar (mean) suspicious3 violent anger3 annoy3 frust3 fear3 if SuspectBehavior3 ==0, ///
		  ytitle("Mean", size(vsmall)) yscale(range(0(.1)1.0)) ylabel(0(.2)1.0, labsize(tiny) nogrid) ///
		  title("Compliant", size(small)) bargap(50) showyvars ///
		  yvaroptions(relabel(1 "Suspicious" 2 "Perceived Danger" 3 "Angry" 4 "Annoyed" 5 "Frustrated" 6 "Fearful") label(labs(vsmall) angle(35))) ///		  
		  blabel(total, pos(outside) format(%4.2f) size(vsmall) c(gs0)) ///
		  bar(2, col(plr1)) bar(3, col(plb1)) bar(4, col(plg1)) bar(5, col(ply1)) bar(6, col(pll1)) ///
		  legend(off) ///
		  scheme(plottig) name(exp3a, replace)
		  
graph bar (mean) suspicious3 violent anger3 annoy3 frust3 fear3 if SuspectBehavior3 ==1, ///
		  ytitle("Mean", size(vsmall)) yscale(range(0(.1)1.0)) ylabel(0(.2)1.0, labsize(tiny) nogrid) ///
		  title("Bad Attitude", size(small)) bargap(50) showyvars ///
		  yvaroptions(relabel(1 "Suspicious" 2 "Perceived Danger" 3 "Angry" 4 "Annoyed" 5 "Frustrated" 6 "Fearful") label(labs(vsmall) angle(35))) ///		  
		  blabel(total, pos(outside) format(%4.2f) size(vsmall) c(gs0)) ///
		  bar(2, col(plr1)) bar(3, col(plb1)) bar(4, col(plg1)) bar(5, col(ply1)) bar(6, col(pll1)) ///
		  legend(off) ///
		  scheme(plottig) name(exp3b, replace)
		  
graph bar (mean) suspicious3 violent anger3 annoy3 frust3 fear3 if SuspectBehavior3 ==2, ///
		  ytitle("Mean", size(vsmall)) yscale(range(0(.1)1.0)) ylabel(0(.2)1.0, labsize(tiny) nogrid) ///
		  title("Noncompliant", size(small)) bargap(50) showyvars ///
		  yvaroptions(relabel(1 "Suspicious" 2 "Perceived Danger" 3 "Angry" 4 "Annoyed" 5 "Frustrated" 6 "Fearful") label(labs(vsmall) angle(35))) ///		  
		  blabel(total, pos(outside) format(%4.2f) size(vsmall) c(gs0)) ///
		  bar(2, col(plr1)) bar(3, col(plb1)) bar(4, col(plg1)) bar(5, col(ply1)) bar(6, col(pll1)) ///
		  legend(off) ///
		  scheme(plottig) name(exp3c, replace)

graph combine exp1a exp1b exp1c exp2a exp2b exp2c exp3a exp3b exp3c, scheme(plottig) ///
      title("Figure 1. The effects of civilian demeanor on respondents' cognitions and emotions.", size(medsmall)) ///
	  note("NOTE: Suspicious is coded 1=Somewhat supicious, suspicious, or very suspicious. Perceived Danger is coded 1=Likely or very likely to become physically combative. Angry is coded 1=Slightly, moderately, or extremely angry." ///
	       "Annoyed is coded 1=slightly, moderately, or extremely annoyed. Frustrated is coded 1=slightly, moderately, or extremely frustrated. Fearful is coded 1=afraid or very afraid.", size(tiny)) 

		   
* Characteristics of the Sample 
	recode q0036 (2 = 1) (1 = 0), gen (Male)
	gen Age = 2018 - q0037_0001
	recode Age (111 348 1148 = .)
	recode q0039 (1=1) (2 3 4 0 = 0), gen (White)
	replace White = 0 if q0038 == 1
	recode q0040 (1/4 = 0) (5/7 = 1), gen (BachDegree)
	clonevar CJYears = q0041_0001

/* check balance of demographics across manipulations:
   if model chi-square statistic is nonsignificant, it indicates
   there is no effect of the demographic variables, taken together, 
   on the manipulation. */

	mlogit SuspectBehavior Male White Age BachDegree CJYears
	mlogit SuspectBehavior2 Male White Age BachDegree CJYears
	mlogit SuspectBehavior3 Male White Age BachDegree CJYears

* Compare sample demographics to agency demographics

	ttest Male  == .9002 // Agency is 90.02% male, sample is 90.13% male
	ttest White == .6925 // Agency is 69.25% white, sample is 67.26% white

	gen twenties = 1 if Age >=20 & Age <= 29
	replace twenties = 0 if twenties != 1
	replace twenties = . if Age == .

	gen thirties = 1 if Age >=30 & Age <= 39
	replace thirties = 0 if thirties != 1
	replace thirties = . if Age == .

	gen forties = 1 if Age >=40 & Age <= 49
	replace forties = 0 if forties != 1
	replace forties = . if Age == .

	gen fiftyup = 1 if Age >= 50
	replace fiftyup = 0 if fiftyup != 1
	replace fiftyup = . if Age == .

	ttest twenties == .1080 // Agency is 10.80% 20s, sample is 6.5%
	ttest thirties == .3631 // Agency is 36.31% 30s, sample is 31.79%
	ttest forties  == .3899 // Agency is 39.99% 40s, sample is 44.32%
	ttest fiftyup  == .1390 // Agency is 13.90% 50+, sample is 17.40%
