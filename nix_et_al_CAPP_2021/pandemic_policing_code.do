* What Does the Public Want Police to Do During Pandemics? A National Experiment
* with Stefan Ivanov & Justin Pickett
* Criminology & Public Policy
* mTurk survey fielded April 15-19, 2020
* Code written 4/30/2020 by JTP
* Last updated 5/4/2020 by JN
********************************************************************************************************

* Call up the data
	use "~\pandemic_policing_data.dta" 

* Set a directory for graphs etc.
	cd ""

* Reverse code the police tactic items so higher scores = support
	local police "Q86_1 Q86_2 Q86_3 Q86_4 Q86_5 Q86_6 Q86_7 Q86_8"
	foreach i in `police' {
		recode `i' (1=5) (2=4) (3=3) (4=2) (5=1), gen(R`i')
	}
	
* Dependent Variables - Support for Policing (NOTE: Only two meaningful factors)
	rename RQ86_1 cut_patrol 
	rename RQ86_2 cut_traffic
	rename RQ86_3 cut_drug
	rename RQ86_4 cut_prop
	rename RQ86_5 only_911
	rename RQ86_6 focus_vio
	rename RQ86_7 enf_socd
	rename RQ86_8 parties
	label define support 1 "1. Strongly oppose" 2 "2. Oppose" 3 "3. Neither" 4 "4. Support" 5 "5. Strongly support"
	label values cut_patrol cut_traffic cut_drug cut_prop only_911 focus_vio enf_socd parties support 
	
	pwcorr cut_patrol cut_traffic cut_drug cut_prop only_911 focus_vio enf_socd parties, sig
	factor cut_patrol cut_traffic cut_drug cut_prop only_911 focus_vio enf_socd parties, mine(.78)
	rotate, promax
	alpha cut_patrol cut_traffic cut_drug cut_prop only_911 focus_vio
	
	egen prot = rmean(cut_patrol cut_traffic cut_drug cut_prop only_911 focus_vio)
	egen protective = std(prot)
	label variable protective "Support for Precautionary Policing"
	
	alpha enf_socd parties
	pwcorr enf_socd parties, sig
	egen sdist = rmean(enf_socd parties)
	egen sdistance = std(sdist)
	label variable sdistance "Support for Social-Distance Policing"
	pwcorr protective sdistance, sig

* Independent Variable - Experimental Information Prime
	recode covidR (1=0) (3=1), gen (info)
	label define info 0 "0. Control" 1 "1. Jails/Prisons Hazard" 2 "2. Policing Hazard"
	label values info info
	label variable info "Experiment: Information Received"

* Independent Variable - Moral Foundations - Authority
	recode Q88 Q89 Q90 Q91 (5=3) (6=4) (7=5)
	gen children = 6 - Q88
	gen dif_roles = 6 - Q89
	gen laws = 6 - Q90
	gen soldier = 6 - Q91
	label define Agree 1 "1. Strongly disagree" 2 "2. Disagree" 3 "3. Neither" 4 "4. Agree" 5 "5. Strongly agree"
	label values children dif_roles laws soldier Agree
	
	factor children dif_roles laws soldier, mine(1)
	alpha children dif_roles laws soldier
	egen authority = rmean(children dif_roles laws soldier)
	label variable authority "Moral Foundations = Authority/Respect"

* Independent Variable - Racial Resentment
	gen overcame = 6 - Q97
	clonevar generations = Q98
	clonevar gottenless = Q99
	gen workharder = 6 - Q100
	clonevar discrim = Q101
	pwcorr overcame generations gottenless workharder discrim, sig
	
	factor overcame generations gottenless workharder discrim, mine(1)
	alpha overcame generations gottenless workharder discrim
	egen rresent = rmean(overcame generations gottenless workharder discrim)
	label variable rresent "Racial Resentment"

* Independent Variable - Procedural Justice 
	gen dignity = 6 - Q109_1
	gen fairly = 6 - Q109_2
	gen equally = 6 - Q109_3
	gen rights = 6 - Q109_4
	gen explain = 6 - Q109_5
	gen listen = 6 - Q109_6
	gen care = 6 - Q109_7
	
	factor dignity fairly equally rights explain listen care, mine(1)
	alpha dignity fairly equally rights explain listen care
	egen pjustice = rmean(dignity fairly equally rights explain listen care)
	label variable pjustice "Perceived Procedural Justice"

* Independent Variable - Personal Fear of COVID
	recode Q110 (4=1) (3=2) (2=3) (1=4), gen (fear)
	label define fear 1 "1. Not worried at all" 2 "2. Not too worried" 3 "3. Somewhat worried" 4 "4. Very worried"
	label values fear fear
	label variable fear "Personal Fear of COVID"

* Independent Variable - Altruistic Fear of COVID 
	gen family = 6 - Q112_1
	gen friends = 6 - Q112_2
	gen neighbors = 6 - Q112_3
	gen doctors = 6 - Q112_4
	gen police = 6 - Q112_5
	gen people = 6 - Q112_6
	
	factor family friends neighbors doctors police people, mine(1)
	alpha family friends neighbors doctors police people
	egen afear = rmean (family friends neighbors doctors police people)
	label variable afear "Altruistic Fear of COVID"

* Control Variables - Demographics 
	clonevar age = Q113
	
	clonevar latino = Q115
	recode latino (2=0)
	
	clonevar white = Q116
	recode white (2/7 = 0)
	
	clonevar male = Q117
	recode male (2/4 = 0)
	
	recode Q122 (2=1) (1 3 4 5 =0), gen (married)
	
	recode Q125 (1 2 = 1) (3=2) (4=4) (5=3) (6=5), gen (education)
	label define education 1 "1. High school or less" 2 "2. Some college" 3 "3. Associate degree" 4 "4. Bachelor degree" 5 "5. Graduate degree"
	label values education education
	
	clonevar income = Q127
	
	clonevar employed = Q128
	recode employed (2/7 =0)
 
* Control Variables - Political Ideology
	clonevar repub = Q118
  
* Control Variables - Victimization Status (NOTE: Highly correlated, so combining)
	clonevar fvictim = Q123  
	recode fvictim (2=0)
	clonevar pvictim = Q124
	recode pvictim (2=0)
	gen victim = 0
	replace victim = 1 if fvictim ==1
	replace victim = 1 if pvictim ==1
	replace victim = . if fvictim ==.
	replace victim = . if pvictim ==.
	label define victim 0 "0. Not a victim" 1 "1. Victim in Family"
	label values victim victim
	label variable victim "Victimization Status"


* Control Variable - Attention to COVID NEWS 
	recode Q111 (4=1) (3=2) (2=3) (1=4), gen (news)
	label define news 1 "1. Not at all closely" 2 "2. Not too closely" 3 "3. Fairly closely" 4 "4. Very closely"
	label values news news 
	label variable news "Attention to COVID news"


*********************************************************************************************************
										* MAIN ANALYSES *
*********************************************************************************************************

* Table 1 - Descriptive Statistics 
	sum authority rresent pjustice fear afear ///
		white latino male age married education income employed repub victim news

* Figure 1 - Support for Pandemic Policing 
	recode cut_patrol(4 5 =1) (1 2 3 =0), gen (cut_patrolb)
	recode cut_traffic (4 5 =1) (1 2 3 =0), gen (cut_trafficb)
	recode cut_drug (4 5 =1) (1 2 3 =0), gen (cut_drugb)
	recode cut_prop (4 5 =1) (1 2 3 =0), gen (cut_propb)
	recode only_911 (4 5 =1) (1 2 3 =0), gen (only_911b)
	recode focus_vio (4 5 =1) (1 2 3 =0), gen (focus_viob)
	recode enf_socd (4 5 =1) (1 2 3 =0), gen (enf_socdb)
	recode parties (4 5 =1) (1 2 3 =0), gen (partiesb)
	label define supportb 0 "0. Oppose, Neither" 1 "1. Support"
	label values cut_patrolb cut_trafficb cut_drugb cut_propb only_911b focus_viob enf_socdb partiesb supportb
	sum cut_patrolb cut_trafficb cut_drugb cut_propb only_911b focus_viob enf_socdb partiesb
	
	* convert each variable above into a percentage
		local fig "cut_patrolb cut_trafficb cut_drugb cut_propb only_911b focus_viob enf_socdb partiesb"
		foreach i in `fig' {
			egen pct_`i' = mean(100 * `i')
		}
		
	graph bar pct_*, ///
	blabel(total, pos(outside) format(%4.0f) size(small)) bargap(25) ///
	yscale(range(0(10)70)) ylabel(0(10)70, labs(small)) ///
	showyvars yvar(label(labs(vsmall) angle(45)) ///
		relabel(1 "Less Foot Patrol" ///
				2 "Fewer Traffic Stops" ///
				3 "Less Drug Enforcement" ///
				4 "Less Property Enforcement" ///
				5 "Only 911 Calls" ///
				6 "Focus on Violence" ///
				7 "Enforce Distancing" ///
				8 "Shut Down Gatherings")) ///
	bar(1, fc(gs16) lc(gs0)) ///
	bar(2, fc(gs16) lc(gs0)) ///
	bar(3, fc(gs16) lc(gs0)) ///
	bar(4, fc(gs16) lc(gs0)) ///
	bar(5, fc(gs16) lc(gs0)) ///
	bar(6, fc(gs16) lc(gs0)) ///
	bar(7, fc(gs3)  lc(gs0)) ///
	bar(8, fc(gs3)  lc(gs0)) ///
	leg(pos(6) rows(1) order(1 7) label(1 "Precautionary Policing") label(7 "Social Distance Policing") size(small)) ///
	note("Note: Numbers displayed reflect % of respondents who {it:support} or {it:strongly support} each style.", ///
		size(vsmall) span margin(0 0 0 3)) 
			
	graph export "fig 1.pdf", as(pdf) replace
	graph export "fig 1.png", as(png) replace
	graph export "fig 1.tif", width(1800) replace

* Table 2 - Predicting Support for Health-Protective and Social-Distance Policing 
	regress protective i.info, robust 
	regress protective i.info authority rresent pjustice fear afear ///
		white latino male age married education income employed repub victim news, robust

	regress sdistance i.info, robust 
	regress sdistance i.info authority rresent pjustice fear afear ///
		white latino male age married education income employed repub victim news, robust


*********************************************************************************************************
									* SUPPLEMENTAL ANALYSES *
*********************************************************************************************************


* By Attention Check
	regress protective i.info authority rresent pjustice fear afear ///
		white latino male age married education income employed repub victim news if attn1 ==1, robust
	regress sdistance i.info authority rresent pjustice fear afear ///
		white latino male age married education income employed repub victim news if attn1 ==1, robust

	regress protective i.info authority rresent pjustice fear afear ///
		white latino male age married education income employed repub victim news if attn2 ==1, robust
	regress sdistance i.info authority rresent pjustice fear afear ///
		white latino male age married education income employed repub victim news if attn2 ==1, robust

	regress protective i.info authority rresent pjustice fear afear ///
		white latino male age married education income employed repub victim news if attnB ==1, robust
	regress sdistance i.info authority rresent pjustice fear afear ///
		white latino male age married education income employed repub victim news if attnB ==1, robust
