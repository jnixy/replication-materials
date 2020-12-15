/********************************************************************************************************
- Nix, Todak, & Tregle (2020)
- "Understanding Body-Worn Camera Diffusion in US Policing"
- Police Quarterly, 23(3) pp. 396-422
- Code written 3/22/2019
- Last updated 2/6/2020
********************************************************************************************************/

/* Data collection began 2/18/2018 and ended 4/16/2018 */
version 15.1

* Call up the data
	use "~/PQ_BWC_diffusion.dta" 

* CREATE VARIABLES
	
	/* Jurisdiction's avg population, 2014-16 */
		egen avgpop = rmean(ucrpop14 ucrpop15 ucrpop16)
		sum avgpop, detail

		gen ln_avgpop = ln(avgpop)
		sum avgpop, detail

	/* US Region */
		gen region = .
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
		label define region 1 "northeast" 2 "midwest" 0 "south" 3 "west"				 
		label values region region
		fre region

		gen ne = .
		replace ne = 1 if region == 1
		replace ne = 0 if region != 1

		gen sou = .
		replace sou = 1 if region == 0
		replace sou = 0 if region != 0

		gen mw = .
		replace mw = 1 if region == 2
		replace mw = 0 if region != 2

		gen we = .
		replace we = 1 if region == 3
		replace we = 0 if region != 3
		
	/* support from institutional sovereigns */
	// drop city manager b/c it didn't always apply and we can't be sure everyone skipped it if they should've
		drop q7c
		factor q7*, mine(1)
		alpha q7*
		egen sovs = rmean(q7*)

	/* %Black */
		gen pblack = (black2016/pop2016)*100
		label var pblack "%Black, 2016"
		
		gen ln_pblack = ln(pblack+1) // reduce skew and add constant to deal with values < 1
		label var ln_pblack "ln(%Black, 2016)"

	/* %Hispanic */
		gen phisp = (hisp2016/pop2016)*100
		label var phisp "%Hispanic, 2016"
		
		gen ln_phisp = ln(phisp+1) // reduce skew
		label var ln_phisp "ln(%Hispanic, 2010)"

	/* state level population and OIS, 2015-2017 */
	// see https://www.census.gov/data/datasets/2017/demo/popest/state-total.html#par_textimage_500989927

		gen statepop15 = .
		replace statepop15 = 4850858 if state == "al"
		replace statepop15 = 737979 if state == "ak"
		replace statepop15 = 6802262 if state == "az"
		replace statepop15 = 2975626 if state == "ar"
		replace statepop15 = 39032444 if state == "ca"
		replace statepop15 = 5440445 if state == "co"
		replace statepop15 = 3593862 if state == "ct"
		replace statepop15 = 944107 if state == "de"
		replace statepop15 = 20268567 if state == "fl"
		replace statepop15 = 10199533 if state == "ga"
		replace statepop15 = 1426320 if state == "hi"
		replace statepop15 = 1649324 if state == "id"
		replace statepop15 = 12862051 if state == "il"
		replace statepop15 = 6610596 if state == "in"
		replace statepop15 = 3118473 if state == "ia"
		replace statepop15 = 2905789 if state == "ks"
		replace statepop15 = 4422057 if state == "ky"
		replace statepop15 = 4671211 if state == "la"
		replace statepop15 = 1327787 if state == "me"
		replace statepop15 = 6000561 if state == "md"
		replace statepop15 = 6794002 if state == "ma"
		replace statepop15 = 9918170 if state == "mi"
		replace statepop15 = 5483238 if state == "mn"
		replace statepop15 = 2985297 if state == "ms"
		replace statepop15 = 6072640 if state == "mo"
		replace statepop15 = 1028317 if state == "mt"
		replace statepop15 = 1893564 if state == "ne"
		replace statepop15 = 2883057 if state == "nv"
		replace statepop15 = 1330134 if state == "nh"
		replace statepop15 = 8960001 if state == "nj"
		replace statepop15 = 2082264 if state == "nm"
		replace statepop15 = 19819347 if state == "ny"
		replace statepop15 = 10041769 if state == "nc"
		replace statepop15 = 754859 if state == "nd"
		replace statepop15 = 11606027 if state == "oh"
		replace statepop15 = 3904353 if state == "ok"
		replace statepop15 = 4016537 if state == "or"
		replace statepop15 = 12791124 if state == "pa"
		replace statepop15 = 1055916 if state == "ri"
		replace statepop15 = 4892423 if state == "sc"
		replace statepop15 = 854036 if state == "sd"
		replace statepop15 = 6590726 if state == "tn"
		replace statepop15 = 27454880 if state == "tx"
		replace statepop15 = 2984917 if state == "ut"
		replace statepop15 = 624455 if state == "vt"
		replace statepop15 = 8366767 if state == "va"
		replace statepop15 = 7152818 if state == "wa"
		replace statepop15 = 1839767 if state == "wv"
		replace statepop15 = 5759744 if state == "wi"
		replace statepop15 = 586102 if state == "wy"

		gen statepop16 = .
		replace statepop16 = 4860545 if state == "al"
		replace statepop16 = 741522 if state == "ak"
		replace statepop16 = 6908642 if state == "az"
		replace statepop16 = 2988231 if state == "ar"
		replace statepop16 = 39296476 if state == "ca"
		replace statepop16 = 5530105 if state == "co"
		replace statepop16 = 3587685 if state == "ct"
		replace statepop16 = 952698 if state == "de"
		replace statepop16 = 20656589 if state == "fl"
		replace statepop16 = 10313620 if state == "ga"
		replace statepop16 = 1428683 if state == "hi"
		replace statepop16 = 1680026 if state == "id"
		replace statepop16 = 12835726 if state == "il"
		replace statepop16 = 6634007 if state == "in"
		replace statepop16 = 3130869 if state == "ia"
		replace statepop16 = 2907731 if state == "ks"
		replace statepop16 = 4436113 if state == "ky"
		replace statepop16 = 4686157 if state == "la"
		replace statepop16 = 1330232 if state == "me"
		replace statepop16 = 6024752 if state == "md"
		replace statepop16 = 6823721 if state == "ma"
		replace statepop16 = 9933445 if state == "mi"
		replace statepop16 = 5525050 if state == "mn"
		replace statepop16 = 2985415 if state == "ms"
		replace statepop16 = 6091176 if state == "mo"
		replace statepop16 = 1038656 if state == "mt"
		replace statepop16 = 1907603 if state == "ne"
		replace statepop16 = 2939254 if state == "nv"
		replace statepop16 = 1335015 if state == "nh"
		replace statepop16 = 8978416 if state == "nj"
		replace statepop16 = 2085432 if state == "nm"
		replace statepop16 = 19836286 if state == "ny"
		replace statepop16 = 10156689 if state == "nc"
		replace statepop16 = 755548 if state == "nd"
		replace statepop16 = 11622554 if state == "oh"
		replace statepop16 = 3921207 if state == "ok"
		replace statepop16 = 4085989 if state == "or"
		replace statepop16 = 12787085 if state == "pa"
		replace statepop16 = 1057566 if state == "ri"
		replace statepop16 = 4959822 if state == "sc"
		replace statepop16 = 861542 if state == "sd"
		replace statepop16 = 6649404 if state == "tn"
		replace statepop16 = 27904862 if state == "tx"
		replace statepop16 = 3044321 if state == "ut"
		replace statepop16 = 623354 if state == "vt"
		replace statepop16 = 8414380 if state == "va"
		replace statepop16 = 7280934 if state == "wa"
		replace statepop16 = 1828637 if state == "wv"
		replace statepop16 = 5772917 if state == "wi"
		replace statepop16 = 584910 if state == "wy"

		gen statepop17 = .
		replace statepop17 = 4874747 if state == "al"
		replace statepop17 = 739795 if state == "ak"
		replace statepop17 = 7016270 if state == "az"
		replace statepop17 = 3004279 if state == "ar"
		replace statepop17 = 39536653 if state == "ca"
		replace statepop17 = 5607154 if state == "co"
		replace statepop17 = 3588184 if state == "ct"
		replace statepop17 = 961939 if state == "de"
		replace statepop17 = 20984400 if state == "fl"
		replace statepop17 = 10429379 if state == "ga"
		replace statepop17 = 1427538 if state == "hi"
		replace statepop17 = 1716943 if state == "id"
		replace statepop17 = 12802023 if state == "il"
		replace statepop17 = 6666818 if state == "in"
		replace statepop17 = 3145711 if state == "ia"
		replace statepop17 = 2913123 if state == "ks"
		replace statepop17 = 4454189 if state == "ky"
		replace statepop17 = 4684333 if state == "la"
		replace statepop17 = 1335907 if state == "me"
		replace statepop17 = 6052177 if state == "md"
		replace statepop17 = 6859819 if state == "ma"
		replace statepop17 = 9962311 if state == "mi"
		replace statepop17 = 5576606 if state == "mn"
		replace statepop17 = 2984100 if state == "ms"
		replace statepop17 = 6113532 if state == "mo"
		replace statepop17 = 1050493 if state == "mt"
		replace statepop17 = 1920076 if state == "ne"
		replace statepop17 = 2998039 if state == "nv"
		replace statepop17 = 1342795 if state == "nh"
		replace statepop17 = 9005644 if state == "nj"
		replace statepop17 = 2088070 if state == "nm"
		replace statepop17 = 19849399 if state == "ny"
		replace statepop17 = 10273419 if state == "nc"
		replace statepop17 = 755393 if state == "nd"
		replace statepop17 = 11658609 if state == "oh"
		replace statepop17 = 3930864 if state == "ok"
		replace statepop17 = 4142776 if state == "or"
		replace statepop17 = 12805537 if state == "pa"
		replace statepop17 = 1059639 if state == "ri"
		replace statepop17 = 5024369 if state == "sc"
		replace statepop17 = 869666 if state == "sd"
		replace statepop17 = 6715984 if state == "tn"
		replace statepop17 = 28304596 if state == "tx"
		replace statepop17 = 3101833 if state == "ut"
		replace statepop17 = 623657 if state == "vt"
		replace statepop17 = 8470020 if state == "va"
		replace statepop17 = 7405743 if state == "wa"
		replace statepop17 = 1815857 if state == "wv"
		replace statepop17 = 5795483 if state == "wi"
		replace statepop17 = 579315 if state == "wy"

	/* fatal OIS per state, 2015-2017 */
	// see WAPO's "Fatal Force" database
		gen ois15 = .
		replace ois15 = 4 if state == "ak"
		replace ois15 = 17 if state == "al"
		replace ois15 = 5 if state == "ar"
		replace ois15 = 42 if state == "az"
		replace ois15 = 190 if state == "ca"
		replace ois15 = 29 if state == "co"
		replace ois15 = 2 if state == "ct"
		replace ois15 = 3 if state == "de"
		replace ois15 = 61 if state == "fl"
		replace ois15 = 29 if state == "ga"
		replace ois15 = 2 if state == "hi"
		replace ois15 = 5 if state == "ia"
		replace ois15 = 7 if state == "id"
		replace ois15 = 21 if state == "il"
		replace ois15 = 19 if state == "in"
		replace ois15 = 9 if state == "ks"
		replace ois15 = 16 if state == "ky"
		replace ois15 = 27 if state == "la"
		replace ois15 = 9 if state == "ma"
		replace ois15 = 15 if state == "md"
		replace ois15 = 2 if state == "me"
		replace ois15 = 16 if state == "mi"
		replace ois15 = 12 if state == "mn"
		replace ois15 = 21 if state == "mo"
		replace ois15 = 8 if state == "ms"
		replace ois15 = 4 if state == "mt"
		replace ois15 = 23 if state == "nc"
		replace ois15 = 1 if state == "nd"
		replace ois15 = 8 if state == "ne"
		replace ois15 = 3 if state == "nh"
		replace ois15 = 15 if state == "nj"
		replace ois15 = 20 if state == "nm"
		replace ois15 = 19 if state == "nv"
		replace ois15 = 19 if state == "ny"
		replace ois15 = 29 if state == "oh"
		replace ois15 = 32 if state == "ok"
		replace ois15 = 15 if state == "or"
		replace ois15 = 18 if state == "pa"
		replace ois15 = 0 if state == "ri"
		replace ois15 = 19 if state == "sc"
		replace ois15 = 3 if state == "sd"
		replace ois15 = 20 if state == "tn"
		replace ois15 = 100 if state == "tx"
		replace ois15 = 10 if state == "ut"
		replace ois15 = 18 if state == "va"
		replace ois15 = 1 if state == "vt"
		replace ois15 = 16 if state == "wa"
		replace ois15 = 11 if state == "wi"
		replace ois15 = 10 if state == "wv"
		replace ois15 = 6 if state == "wy"

		gen ois16 = .
		replace ois16 = 7 if state == "ak"
		replace ois16 = 25 if state == "al"
		replace ois16 = 15 if state == "ar"
		replace ois16 = 50 if state == "az"
		replace ois16 = 138 if state == "ca"
		replace ois16 = 31 if state == "co"
		replace ois16 = 4 if state == "ct"
		replace ois16 = 1 if state == "de"
		replace ois16 = 60 if state == "fl"
		replace ois16 = 26 if state == "ga"
		replace ois16 = 6 if state == "hi"
		replace ois16 = 5 if state == "ia"
		replace ois16 = 6 if state == "id"
		replace ois16 = 26 if state == "il"
		replace ois16 = 14 if state == "in"
		replace ois16 = 10 if state == "ks"
		replace ois16 = 18 if state == "ky"
		replace ois16 = 19 if state == "la"
		replace ois16 = 12 if state == "ma"
		replace ois16 = 15 if state == "md"
		replace ois16 = 2 if state == "me"
		replace ois16 = 13 if state == "mi"
		replace ois16 = 14 if state == "mn"
		replace ois16 = 21 if state == "mo"
		replace ois16 = 8 if state == "ms"
		replace ois16 = 5 if state == "mt"
		replace ois16 = 33 if state == "nc"
		replace ois16 = 1 if state == "nd"
		replace ois16 = 7 if state == "ne"
		replace ois16 = 2 if state == "nh"
		replace ois16 = 12 if state == "nj"
		replace ois16 = 21 if state == "nm"
		replace ois16 = 14 if state == "nv"
		replace ois16 = 17 if state == "ny"
		replace ois16 = 26 if state == "oh"
		replace ois16 = 26 if state == "ok"
		replace ois16 = 15 if state == "or"
		replace ois16 = 22 if state == "pa"
		replace ois16 = 2 if state == "ri"
		replace ois16 = 17 if state == "sc"
		replace ois16 = 4 if state == "sd"
		replace ois16 = 22 if state == "tn"
		replace ois16 = 82 if state == "tx"
		replace ois16 = 8 if state == "ut"
		replace ois16 = 17 if state == "va"
		replace ois16 = 2 if state == "vt"
		replace ois16 = 26 if state == "wa"
		replace ois16 = 17 if state == "wi"
		replace ois16 = 12 if state == "wv"
		replace ois16 = 2 if state == "wy"

		gen ois17 = .
		replace ois17 = 8 if state == "ak"
		replace ois17 = 25 if state == "al"
		replace ois17 = 12 if state == "ar"
		replace ois17 = 44 if state == "az"
		replace ois17 = 162 if state == "ca"
		replace ois17 = 31 if state == "co"
		replace ois17 = 6 if state == "ct"
		replace ois17 = 6 if state == "de"
		replace ois17 = 58 if state == "fl"
		replace ois17 = 29 if state == "ga"
		replace ois17 = 3 if state == "hi"
		replace ois17 = 5 if state == "ia"
		replace ois17 = 6 if state == "id"
		replace ois17 = 20 if state == "il"
		replace ois17 = 19 if state == "in"
		replace ois17 = 12 if state == "ks"
		replace ois17 = 17 if state == "ky"
		replace ois17 = 19 if state == "la"
		replace ois17 = 3 if state == "ma"
		replace ois17 = 9 if state == "md"
		replace ois17 = 9 if state == "me"
		replace ois17 = 14 if state == "mi"
		replace ois17 = 9 if state == "mn"
		replace ois17 = 31 if state == "mo"
		replace ois17 = 17 if state == "ms"
		replace ois17 = 6 if state == "mt"
		replace ois17 = 22 if state == "nc"
		replace ois17 = 3 if state == "nd"
		replace ois17 = 0 if state == "ne"
		replace ois17 = 3 if state == "nh"
		replace ois17 = 12 if state == "nj"
		replace ois17 = 21 if state == "nm"
		replace ois17 = 16 if state == "nv"
		replace ois17 = 16 if state == "ny"
		replace ois17 = 34 if state == "oh"
		replace ois17 = 26 if state == "ok"
		replace ois17 = 12 if state == "or"
		replace ois17 = 23 if state == "pa"
		replace ois17 = 1 if state == "ri"
		replace ois17 = 12 if state == "sc"
		replace ois17 = 3 if state == "sd"
		replace ois17 = 27 if state == "tn"
		replace ois17 = 69 if state == "tx"
		replace ois17 = 7 if state == "ut"
		replace ois17 = 23 if state == "va"
		replace ois17 = 1 if state == "vt"
		replace ois17 = 38 if state == "wa"
		replace ois17 = 24 if state == "wi"
		replace ois17 = 11 if state == "wv"
		replace ois17 = 1 if state == "wy"

	/* average annual OIS rate */
		gen oisrate15 = (ois15/statepop15)*1000000
		gen oisrate16 = (ois16/statepop16)*1000000
		gen oisrate17 = (ois17/statepop17)*1000000

		gen avgoisrate = (oisrate15+oisrate16+oisrate17)/3

	/* average violent crime rate, 2014 to 2016 */
		gen vcrate16 = (vcrime16/ucrpop16)*100000
		gen vcrate15 = (vcrime15/ucrpop15)*100000
		gen vcrate14 = (vcrime14/ucrpop14)*100000
		
		egen avgvcrate = rmean(vcrate14 vcrate15 vcrate16)
		label var avgvcrate "Avg. Violent Crime Rate, 2014-16"
		
		gen ln_avgvcrate = ln(avgvcrate+1) // reduce skew
		label var ln_avgvcrate "ln(Avg. Violent Crime Rate, 2014-16)"
			
	/* DEPENDENT VARIABLE: Does your agency currently use BWCs? */
		gen BWC = . 
		replace BWC = 0 if q18 == 0 & mode == 1
		replace BWC = 1 if q18 == 1 & mode == 1
		replace BWC = 1 if q18 == 1 & mode == 0
		replace BWC = 0 if q18 == 2 & mode == 0
		tab BWC
		
	/* DEPENDENT VARIABLE: Support law requiring release of BWC footage */
		gen BWClaw = 6 - q12

	/* Sample weights 
		 0-24: 74.26/22.41 = 3.3137
		25-49: 13.38/25.86 =  .5174
		50-99:  6.93/25.26 =  .2743
		 100+:  5.43/26.47 =  .2051
		*/
		gen fweight = .
		replace fweight =  .2051 if sworn == 4
		replace fweight =  .2743 if sworn == 3
		replace fweight =  .5174 if sworn == 2
		replace fweight = 3.3137 if sworn == 1
		tab fweight sworn 

	/* missing dummy */
		gen missing = 0
		replace missing = 1 if BWClaw == . | ///
							   BWC == . | ///
							   avgpop == . | ///
							   avgoisrate == . | ///
							   ln_avgvcrate == . | ///
							   ln_pblack == . | ///
							   ln_phisp == . | /// |
							   sovs == . | ///
							   PercentTrump == . | ///
							   region == . | ///
							   sworn == . 
		tab missing

*********************************************************************************************************
/* ANALYSIS */


* BWC usage by agency size 
	tab sworn BWC, row
	ttest BWC, by(sworn2)
	
* Table 1: Response rates across Strata
	tab sworn
		di 149/624
		di 172/624
		di 168/624
		di 176/624

* Table 2: Prevalence estimates
	svyset _n [pweight=fweight]

	svy: proportion BWC if sworn==1
	svy: proportion BWC if sworn==2
	svy: proportion BWC if sworn==3
	svy: proportion BWC if sworn==4
	svy: proportion BWC

* Table 3: Descriptives 
	sum BWC BWClaw avgpop ne sou mw we sovs PercentTrump pblack phisp avgoisrate avgvcrate if sworn == 1 & missing !=1
	sum BWC BWClaw avgpop ne sou mw we sovs PercentTrump pblack phisp avgoisrate avgvcrate if sworn == 2 & missing !=1
	sum BWC BWClaw avgpop ne sou mw we sovs PercentTrump pblack phisp avgoisrate avgvcrate if sworn == 3 & missing !=1
	sum BWC BWClaw avgpop ne sou mw we sovs PercentTrump pblack phisp avgoisrate avgvcrate if sworn == 4 & missing !=1

* Table 4: Predicting BWC usage, clustered by county
	logit BWC ln_avgpop sou mw we sovs PercentTrump ln_pblack ln_phisp avgoisrate ln_avgvcrate if sworn ==1 & missing != 1, vce(cluster FIPS)
	di %6.3f e(chi2)
	
	logit BWC ln_avgpop sou mw we sovs PercentTrump ln_pblack ln_phisp avgoisrate ln_avgvcrate if sworn ==2 & missing != 1, vce(cluster FIPS)
	di %6.3f e(chi2)
	
	logit BWC ln_avgpop sou mw we sovs PercentTrump ln_pblack ln_phisp avgoisrate ln_avgvcrate if sworn ==3 & missing != 1, vce(cluster FIPS)
	di %6.3f e(chi2)
	
	logit BWC ln_avgpop sou mw we sovs PercentTrump ln_pblack ln_phisp avgoisrate ln_avgvcrate if sworn ==4 & missing != 1, vce(cluster FIPS)
	di %6.3f e(chi2)  

* Table 5: Predicting Support for legislation requiring release of BWC footage, clustered by county
	ologit BWClaw BWC ln_avgpop sou mw we sovs PercentTrump ln_pblack ln_phisp avgoisrate ln_avgvcrate if sworn ==1 & missing != 1, vce(cluster FIPS)
	di %6.3f e(chi2)
	
	ologit BWClaw BWC ln_avgpop sou mw we sovs PercentTrump ln_pblack ln_phisp avgoisrate ln_avgvcrate if sworn ==2 & missing != 1, vce(cluster FIPS)
	di %6.3f e(chi2)
	
	ologit BWClaw BWC ln_avgpop sou mw we sovs PercentTrump ln_pblack ln_phisp avgoisrate ln_avgvcrate if sworn ==3 & missing != 1, vce(cluster FIPS)
	di %6.3f e(chi2)
	
	ologit BWClaw BWC ln_avgpop sou mw we sovs PercentTrump ln_pblack ln_phisp avgoisrate ln_avgvcrate if sworn ==4 & missing != 1, vce(cluster FIPS)
	di %6.3f e(chi2)
	
	

*********************************************************************************************************
/* SUPPLEMENTAL ANALYSES */

	* Check results without 9 SC respondents, who were "required" by law to adopt BWCs (see Endnote #5)

		* Table 4: Predicting BWC usage
			logit BWC ln_avgpop sou mw we sovs PercentTrump ln_pblack ln_phisp avgoisrate ln_avgvcrate if sworn ==1 & missing != 1 & state != "sc", or vce(cluster FIPS) // no one drops, same model
			logit BWC ln_avgpop sou mw we sovs PercentTrump ln_pblack ln_phisp avgoisrate ln_avgvcrate if sworn ==2 & missing != 1 & state != "sc", or vce(cluster FIPS) // 4 fewer cases, no substantive diffs
			logit BWC ln_avgpop sou mw we sovs PercentTrump ln_pblack ln_phisp avgoisrate ln_avgvcrate if sworn ==3 & missing != 1 & state != "sc", or vce(cluster FIPS) // 3 fewer cases, %black goes from p=.096 to p=.127
			logit BWC ln_avgpop sou mw we sovs PercentTrump ln_pblack ln_phisp avgoisrate ln_avgvcrate if sworn ==4 & missing != 1 & state != "sc", or vce(cluster FIPS) // 2 fewer cases, no substantive diffs

		* Table 5: Predicting Support for legislation requiring release of BWC footage
			ologit BWClaw BWC ln_avgpop sou mw we sovs PercentTrump ln_pblack ln_phisp avgoisrate ln_avgvcrate if sworn ==1 & missing != 1 & state != "sc", or vce(cluster FIPS) // no one drops, same model
			ologit BWClaw BWC ln_avgpop sou mw we sovs PercentTrump ln_pblack ln_phisp avgoisrate ln_avgvcrate if sworn ==2 & missing != 1 & state != "sc", or vce(cluster FIPS) // 4 fewer cases, %hisp goes from p=.076 to .125
			ologit BWClaw BWC ln_avgpop sou mw we sovs PercentTrump ln_pblack ln_phisp avgoisrate ln_avgvcrate if sworn ==3 & missing != 1 & state != "sc", or vce(cluster FIPS) // 3 fewer cases, no substantive diffs
			ologit BWClaw BWC ln_avgpop sou mw we sovs PercentTrump ln_pblack ln_phisp avgoisrate ln_avgvcrate if sworn ==4 & missing != 1 & state != "sc", or vce(cluster FIPS) // 2 fewer cases, no substantive diffs
		
	* Full Sample with Weights Applied
		logit BWC ln_avgpop avgoisrate ln_avgvcrate ln_pblack ln_phisp PercentTrump i.region if missing != 1 [pweight=fweight], or
		ologit BWClaw BWC ln_avgpop avgoisrate ln_avgvcrate ln_pblack ln_phisp PercentTrump i.region if missing != 1 [pweight=fweight], or

	* Binary coding of BWClaw */
		gen BWClaw2 = .
		replace BWClaw2 = 1 if BWClaw == 4 | BWClaw == 5
		replace BWClaw2 = 0 if BWClaw == 1 | BWClaw == 2 | BWClaw == 3

		logit BWClaw2 BWC ln_avgpop avgoisrate ln_avgvcrate ln_pblack ln_phisp PercentTrump i.region if sworn ==1 & missing !=1, or
		logit BWClaw2 BWC avgpop avgoisrate ln_avgvcrate ln_pblack ln_phisp PercentTrump i.region if sworn ==2 & missing !=1, or
		logit BWClaw2 BWC ln_avgpop avgoisrate ln_avgvcrate ln_pblack ln_phisp PercentTrump i.region if sworn ==3 & missing !=1, or
		logit BWClaw2 BWC ln_avgpop avgoisrate ln_avgvcrate ln_pblack ln_phisp PercentTrump i.region if sworn ==4 & missing !=1, or
