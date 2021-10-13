* Factors associated with police shooting mortality: A focus on race and a plea for more comprehensive data
* With John Shjarback
* Revised & Resubmitted on 6/29/2021
* Second R&R on 9/9/2021, resubmitted 9/15/2021
* Accepted for publication on 10/12/2021
* Code last updated by JN 9/14/2021 

* Note that to create Figures S1-S4, you need to install Michael Stepner's -maptile- and -spmap- commands (see https://michaelstepner.com/maptile/).
* Uncomment the next three lines to install the necessary packages and files. 
	// ssc install maptile
	// ssc install spmap
	// maptile_install using "http://files.michaelstepner.com/geo_county2014.zip"

* Create macros for data & output folders
	global florida ""
	global texas ""
	global california ""
	global colorado ""
	global pool ""
	global output ""
	
* ################################### CLEANING & MERGING ############################################## *

**********
* IMPORT/CLEAN FLORIDA DATA
* see https://github.com/tbtimes/florida-police-shooting-data
	use "$florida\FL_peopleshot.dta", clear
	
	tab condition	
	drop if condition == "" // 2 cases 
	gen fatal = 1 if condition == "killed" | condition == "suicide"
	replace fatal = 0 if condition == "injured"
	
	gen nonfatal = 1 if fatal == 0
	replace nonfatal = 0 if fatal == 1
	
	tab gender
	gen male = 1 if gender == "M"
	replace male = 0 if gender == "F"
	
	table weapon_choices
	gen deadly_weap = 1 if weapon_choices == "Firearm" | weapon_choices == "Blade/stabbing implement" | ///
		weapon_choices == "Blunt/bludgeoning weapon" | weapon_choices == "Vehicle" | weapon_choices == "Taser" | ///
		weapon_choices == "Other" | weapon_choices == "BB/Pellet Gun" | weapon_choices == "Toy weapon"
	replace deadly_weap = 0 if weapon_choices == "Unarmed"
		
	gen weapon_cat = 1 if deadly_weap == 1
	replace weapon_cat = 2 if weapon_choices == "BB/Pellet Gun" | weapon_choices == "Toy weapon"
	replace weapon_cat = 3 if weapon_choices == "Unarmed"
	replace weapon_cat = 4 if weapon_choices == "Unclear from report"
	label define weapon_catl 1 "deadly" 2 "toy/replica" 3 "unarmed" 4 "undetermined"
	label values weapon_cat weapon_catl
	
* Save as new file ahead of all the merging
	save "$florida\FL_peopleshot_mod.dta", replace
	
* import "cases" file from TBT
	import delimited "$florida\FL09-14.csv", delimiter(comma) varnames(1) clear

	rename id case_id
	rename city_id id

* merge city names from TBT
	merge m:1 id using "$florida\FL_City IDs.dta", nogen

	rename name city_name
	rename id city_id
	rename county_id id

* merge county names from TBT
	merge m:1 id using "$florida\FL_County IDs.dta", nogen

	rename name county_name
	rename id county_id

	drop if case_id == .
	
* merge together with TBT victim data file
	merge 1:m case_id using "$florida\FL_peopleshot_mod.dta"
	
	tab case_id if _merge == 1 // 4 incidents did not appear in victim file.
	drop _merge
	
	gen Date = date(date, "MDY")
	format Date %td
	gen BDay = date(birth_date, "YMD")
	format BDay %td
	gen age = (Date - BDay)/365.25
	
	gen age_cat = .
	replace age_cat = 0 if age < 26
	replace age_cat = 1 if age >= 26 & age < 36
	replace age_cat = 2 if age >= 36 & age < 46
	replace age_cat = 3 if age >= 46
	replace age_cat = . if age == .
	label define agel 0 "25 and under" 1 "26-35" 2 "36-45" 3 "46+"
	label values age_cat agel

	gen mental_illness = 0 if suspect_mentally_ill == "f"
	replace mental_illness = 1 if suspect_mentally_ill == "t"
	
* begin merging FIPS Codes.
* first, clone the city_name variable and eliminate trailing double blanks from several observations
* then, merge in municipality names obtained from Wikipedia.
	gen Place = subinstr(city_name, "  ", "",.)
	
	replace Place = "Winter Garden" if city_name == "Winter Garden "
	merge m:1 Place using "$florida\List of Municipalities in FL.dta"

* check the mismatches
	tab Place if _merge == 1
	
* mostly CDPs or unincorporated communities. pull their counties from Google and recode.
	replace County = "Citrus" 		if Place == "Beverly Hills"
	replace County = "Hillsborough" if Place == "Brandon"
	replace County = "Citrus" 		if Place == "Citrus Springs"
	replace County = "Wakulla"	 	if Place == "Crawfordville"
	replace County = "Volusia"		if Place == "DeLeon Springs"
	replace County = "Walton"		if Place == "Defuniak Springs"
	replace County = "Citrus"		if Place == "Floral City"
	replace County = "Marion"		if Place == "Ft. McCoy"
	replace County = "Seminole"		if Place == "Geneva"
	replace County = "Martin"		if Place == "Hobe Sound"
	replace County = "Pasco"		if Place == "Holiday"
	replace County = "Citrus"		if Place == "Homosassa"
	replace County = "Pasco"		if Place == "Hudson"
	replace County = "Orange"		if Place == "Lake Nona"
	replace County = "Palm Beach"	if Place == "Lake Worth"
	replace County = "Lee"			if Place == "Lehigh Acres"
	replace County = "Palm Beach"	if Place == "Loxahatchee"
	replace County = "Hernando"		if Place == "Masaryktown"
	replace County = "Brevard"		if Place == "Merritt Island"
	replace County = "Brevard"		if Place == "Micco"
	replace County = "Clay"			if Place == "Middleburg"
	replace County = "Santa Rosa"	if Place == "Navarre"
	replace County = "Lee"			if Place == "North Fort Myers"
	replace County = "Marion"		if Place == "Ocklawaha"
	replace County = "Dixie"		if Place == "Old Town"
	replace County = "Santa Rosa"	if Place == "Pace"
	replace County = "Pinellas"		if Place == "Palm Harbor"
	replace County = "Broward"		if Place == "Pampano Beach"
	replace County = "St. Johns"	if Place == "Ponte Vedra Beach"
	replace County = "Charlotte"	if Place == "Port Charlotte"
	replace County = "Hillsborough" if Place == "Riverview"
	replace County = "Putnam"		if Place == "San Mateo"
	replace County = "Hillsborough" if Place == "Seffner"
	replace County = "Hernando"		if Place == "Spring Hill"
	replace County = "Marion"		if Place == "Summerfield"
	replace County = "Escambia"		if Place == "Warrington"
	replace County = "Alachua"		if Place == "Windsor"
	replace County = "Bay"			if Place == "Youngstown"
	replace County = "Nassau"		if Place == "Yulee"
	replace County = "Orange"		if Place == "Zellwood"
	
* still have 11 incidents that TBT could only locate to a county. 
* move those from "county_name" to "County"
	list case_id county_name County if County == ""
	
	replace County = "Miami-Dade"	if case_id == 640 | case_id == 1058
	replace County = "Holmes"		if case_id == 1051
	replace County = "Hillsborough" if case_id == 361
	replace County = "Indian River" if case_id == 1007
	replace County = "Suwannee"	 	if case_id == 1100
	replace County = "Okaloosa"	 	if case_id == 1080
	replace County = "Palm Beach"	if case_id == 515
	replace County = "Washington"	if case_id == 988
	replace County = "Madison"		if case_id == 669
	replace County = "St. Johns"	if case_id == 910
	
* four places are split across two counties, but none were involved in OIS
* so, they can be dropped
	drop if regexm(County, ";") == 1
	
* now, merge in FIPS codes obtained from Wikipedia.
	drop _merge county_name
	rename County county_name
	merge m:1 county_name using "$florida\List of Counties in FL.dta"
	
	rename fips county
	
	gen race_group = 0 if race == "Wh"
	replace race_group = 1 if race == "Blk"
	replace race_group = 2 if race == "Hi"
	replace race_group = 3 if race == "As" | race == "Oth"
	replace race_group = . if race == "Unk"
	label define race_groupl 0 "White" 1 "Black" 2 "Hispanic" 3 "Other"
	label values race_group race_groupl
	
* merge in the florida hospital data that John put together
	preserve
		import excel "$florida\fl_county_hospital.xlsx", sheet("Sheet1") firstrow clear
		rename fips county
		save "$florida\fl_county_hospital.dta", replace
	restore

	merge m:1 county using "$florida\fl_county_hospital.dta", gen(_merge2)
	
	gen trauma_dum = 1 if level1_dum == 1 | level2_dum == 1
	replace trauma_dum = 0 if level1_dum == 0 & level2_dum == 0
	
	egen trauma_count = rsum(total_level1 total_level2)
	tab trauma_count
	
	clonevar level1_ord = total_level1 // 0, 1, 2+
	
	gen trauma_ord = 0 if trauma_count == 0
	replace trauma_ord = 1 if trauma_count == 1
	replace trauma_ord = 2 if trauma_count == 2
	replace trauma_ord = 3 if trauma_count >= 3
	tab trauma_ord
	
	tab trauma_dum fatal, row
	
	rename metro_non metro
	label define metrol 1 "Metropolitan Area" 0 "Non-metropolitan area"
	label values metro metrol
	tab metro
	
	gen urbanicity = 10 - rucc_2013 // see https://www.ers.usda.gov/data-products/rural-urban-continuum-codes/documentation/
	tab urbanicity 
			
* Save FL data into a new dataset that'll store a pooled sample
	preserve
		drop if fatal == .
		gen state = "FL"
		gen pool_ID = _n
		keep state pool_ID fatal race_group male age age_cat mental_illness deadly_weap weapon_cat trauma_dum trauma_ord county metro urbanicity 
		save "$pool\pooled_sample.dta", replace
	restore
		
* Collapse to county level for map
	collapse (sum) fatal nonfatal, by(county)
	
	gen total = fatal + nonfatal
	gen pfatal = (fatal/total)*100
	format pfatal %4.2f
	
* Figure S1: county-level fatality rates in Florida
	gen state = 12
		
		maptile pfatal, geo(county2014) mapif(state==12) cutv(0 25 50 60 70 75) ///
		twopt(title("Florida, 1/1/2009 - 12/31/2014", size(small) margin(top)) ///
		legend(pos(7) size(vsmall) label(2 "0%") label(3 "1-25%") label(4 "26-50%") label(5 "51-60%") label(6 "61-70%") label(7 "71-75%") label(8 ">75%") label(1 "No shootings")) ///
		text(16.3 9.28 ".", size(vhuge)) text(15.82 9.33 "{bf:Orlando}", size(vsmall)) ///
		text(12.5 10.5 ".", size(vhuge)) text(12.2 10.92 "{bf:Miami}", size(vsmall)) ///
		text(15.35 8.20 ".", size(vhuge)) text(15.3 8.32 "{bf:Tampa}", size(vsmall)) ///
		text(18.7 9.0 ".", size(vhuge)) text(18.6 9.5 "{bf:Jacksonville}", size(vsmall)) ///
		text(18.82 6.38 ".", size(vhuge)) text(18.75 6.35 "{bf:Tallahassee}", size(vsmall)) ///
		plotr(margin(large))  ///
		name(FL_tpfatal, replace))

		
**********
* IMPORT/CLEAN COLORADO DATA
* obtained via email from Colorado Office of Research and Statistics, c/o Laurence Lucero (laurence.lucero@state.co.us)
	import excel "$colorado\Subjects_2010-18.xlsx", firstrow clear
	save "$colorado\Subjects_2010-18.dta", replace
	
	import excel "$colorado\Subjects_2019.xlsx", firstrow clear
	save "$colorado\Subjects_2019.dta", replace

	merge m:m AIN using "$colorado\Subjects_2010-18.dta"
	save "$colorado\Subjects_2010-19.dta", replace
	
* Drop 98 "misses"
	drop if WoundedOrKilled == "Neither"
	
* Drop 3 additional incidents where data don't indicate if the person was killed/wounded/missed
	drop if WoundedOrKilled == ""
	
	gen fatal = 1 if WoundedOrKilled == "Killed" | WoundedOrKilled == "Suicide"
	replace fatal = 0 if WoundedOrKilled == "Wounded"

	gen nonfatal = 1 if fatal == 0
	replace nonfatal = 0 if fatal == 1
		
	gen male = 1 if Gender == "Male" | Gender == "male"
	replace male = 0 if Gender == "Female"
	replace male = . if Gender == "Unknown"
	
	gen hispanic = 1 if Ethnicity == "Hispanic"
	replace hispanic = 0 if Ethnicity != "Hispanic"
	replace hispanic = . if Ethnicity == "Unknown" | Ethnicity == ""
	
	gen Race2 = 1 if Race == "White" & (Ethnicity == "Non-Hispanic" | Ethnicity == "Not Hispanic Origin")
	replace Race2 = 2 if Race == "Black" | Race == "Black or African American"
	replace Race2 = 3 if Ethnicity == "Hispanic"
	replace Race2 = 4 if Race == "Asian"
	replace Race2 = 5 if Race == "American Indian or Alaska Native" & Ethnicity != "Hispanic"
	replace Race2 = 6 if Race == "Unknown"
	replace Race2 = 1 if Race == "White" & Ethnicity == "Unknown"
	label define Race2l 1 "White" 2 "Black" 3 "Hispanic" 4 "Asian" 5 "Other" 6 "Unknown"
	label values Race2 Race2l
	
	gen age_cat = .
	replace age_cat = 0 if Age < 26
	replace age_cat = 1 if Age >= 26 & Age < 36
	replace age_cat = 2 if Age >= 36 & Age < 46
	replace age_cat = 3 if Age >= 46
	replace age_cat = . if Age == .
	label define agel 0 "25 and under" 1 "26-35" 2 "36-45" 3 "46+"
	label values age_cat agel
	tab age_cat
	
	gen mental_illness = 1 if Disability == "Mental" | Disability == "Both"
	replace mental_illness = 0 if Disability == "Not Evident" | Disability == "Not evident" | Disability == "Physical" | Disability == "Unknown"
	
	table Weapon
	gen deadly_weap = 1 if Weapon == "Blunt Object" | ///
		Weapon == "Cordless drill" | ///
		Weapon == "Explosives/knives" | ///
		Weapon == "Fire/Incendiary Device" | ///
		Weapon == "Hand Gun and Rifle" | ///
		Weapon == "Handgun" | ///
		Weapon == "Handgun/Knife" | ///
		Weapon == "Knife/Cutting Instrument" | ///
		Weapon == "Motor Vehicle" | ///
		Weapon == "Motor vehicle" | ///
		Weapon == "Multiple Weapons" | ///
		Weapon == "Other" | ///
		Weapon == "Other Firearm" | ///
		Weapon == "Other firearm" | ///
		Weapon == "Rifle" | ///
		Weapon == "Shotgun" | ///
		Weapon == "Shotgun and Handgun" | ///
		Weapon == "Vehicle" | ///
		Weapon == "knife"
	replace deadly_weap = 0 if Weapon == "Motor Vehicle-passenger" | ///
		Weapon == "None" | ///
		Weapon == "Passenger in motor vehicle driven toward officer" | ///
		Weapon == "Unarmed"
	
	gen weapon_cat = 1 if deadly_weap == 1
	replace weapon_cat = 3 if Weapon == "Unarmed" | Weapon == "None" | Weapon == "Motor Vehicle-passenger" | Weapon == "Passenger in motor vehicle driven toward officer"
	replace weapon_cat = 4 if Weapon == "Unknown"
	label define weapon_catl 1 "deadly" 2 "toy/replica" 3 "unarmed" 4 "undetermined"
	label values weapon_cat weapon_catl
	
* Identify the county/fips code for each shooting
* Using http://www.statsamerica.org/CityCountyFinder/
	gen agency = lower(ReportinAgencyName)
	gen county = .
	replace county = 08001 if regexm(agency, "adams") == 1
	replace county = 08001 if regexm(agency, "brighton") == 1
	replace county = 08001 if regexm(agency, "adams") == 1
	replace county = 08001 if regexm(agency, "commerce city") == 1
	replace county = 08001 if regexm(agency, "federal heights") == 1
	replace county = 08001 if regexm(agency, "northglenn") == 1
	replace county = 08001 if regexm(agency, "thornton") == 1
	replace county = 08001 if regexm(agency, "westminster") == 1
	replace county = 08005 if regexm(agency, "arapahoe") == 1
	replace county = 08005 if regexm(agency, "aurora") == 1
	replace county = 08005 if regexm(agency, "englewood") == 1
	replace county = 08013 if regexm(agency, "boulder") == 1
	replace county = 08013 if regexm(agency, "longmont") == 1
	replace county = 08013 if regexm(agency, "louisville") == 1
	replace county = 08013 if regexm(agency, "university of colorado") == 1
	replace county = 08014 if regexm(agency, "broomfield") == 1
	replace county = 08015 if regexm(agency, "buena vista") == 1
	replace county = 08015 if regexm(agency, "chaffee") == 1
	replace county = 08019 if regexm(agency, "clear creek") == 1
	replace county = 08029 if regexm(agency, "delta") == 1
	replace county = 08031 if regexm(agency, "auraria campus") == 1
	replace county = 08031 if regexm(agency, "denver") == 1
	replace county = 08035 if regexm(agency, "castle rock") == 1
	replace county = 08035 if regexm(agency, "douglas") == 1
	replace county = 08035 if regexm(agency, "lone tree") == 1
	replace county = 08035 if regexm(agency, "parker") == 1
	replace county = 08041 if regexm(agency, "colorado springs") == 1
	replace county = 08041 if regexm(agency, "el paso") == 1
	replace county = 08041 if regexm(agency, "fountain") == 1
	replace county = 08043 if regexm(agency, "fremont") == 1
	replace county = 08045 if regexm(agency, "garfield") == 1
	replace county = 08047 if regexm(agency, "black hawk") == 1
	replace county = 08051 if regexm(agency, "gunnison") == 1
	replace county = 08059 if regexm(agency, "arvada") == 1
	replace county = 08059 if regexm(agency, "golden") == 1
	replace county = 08059 if regexm(agency, "jefferson") == 1
	replace county = 08059 if regexm(agency, "lakewood") == 1
	replace county = 08059 if regexm(agency, "wheat ridge") == 1
	replace county = 08065 if regexm(agency, "leadville") == 1
	replace county = 08069 if regexm(agency, "fort collins") == 1
	replace county = 08069 if regexm(agency, "larimer") == 1
	replace county = 08069 if regexm(agency, "loveland") == 1
	replace county = 08071 if regexm(agency, "trinidad") == 1
	replace county = 08077 if regexm(agency, "fruita") == 1
	replace county = 08077 if regexm(agency, "grand junction") == 1
	replace county = 08077 if regexm(agency, "mesa") == 1
	replace county = 08081 if regexm(agency, "colorado parks") == 1
	replace county = 08083 if regexm(agency, "cortez") == 1
	replace county = 08083 if regexm(agency, "montezuma") == 1
	replace county = 08085 if regexm(agency, "montrose") == 1
	replace county = 08101 if regexm(agency, "colorado state patrol") == 1
	replace county = 08101 if regexm(agency, "pueblo") == 1
	replace county = 08103 if regexm(agency, "rangely") == 1
	replace county = 08119 if regexm(agency, "woodland park") == 1
	replace county = 08123 if regexm(agency, "fort lupton") == 1
	replace county = 08123 if regexm(agency, "greeley") == 1
	replace county = 08123 if regexm(agency, "la salle") == 1
	replace county = 08123 if regexm(agency, "weld") == 1
	
* merge in the colorado hospital data that John put together
	preserve
		import excel "$colorado\co_county_hospital.xlsx", sheet("Sheet1") firstrow clear
		rename fips county
		save "$colorado\co_county_hospital.dta", replace
	restore

	merge m:1 county using "$colorado\co_county_hospital.dta", gen(_merge2)
	
	gen trauma_dum = 1 if level1_dum == 1 | level2_dum == 1
	replace trauma_dum = 0 if level1_dum == 0 & level2_dum == 0
	
	egen trauma_count = rsum(total_level1 total_level2)
	tab trauma_count
	
	clonevar level1_ord = total_level1
	
	gen trauma_ord = 0 if trauma_count == 0
	replace trauma_ord = 1 if trauma_count == 1
	replace trauma_ord = 2 if trauma_count == 2
	replace trauma_ord = 3 if trauma_count >= 3
	tab trauma_ord
	
	rename metro_non metro
	label define metrol 1 "Metropolitan Area" 0 "Non-metropolitan area"
	label values metro metrol
	tab metro
	
	gen urbanicity = 10 - rucc_2013 // see https://www.ers.usda.gov/data-products/rural-urban-continuum-codes/documentation/
	tab urbanicity 
	
	* If victim had a Race listed, but Ethnicity was listed as "Not known," recode hispanic to 0 (N=35)
		replace hispanic = 0 if Race2 == 1 & hispanic == .
		replace hispanic = 0 if Race2 == 2 & hispanic == .
		replace hispanic = 0 if Race2 == 5 & hispanic == .
		
		gen race_group = 0 if Race2 == 1
		replace race_group = 1 if Race2 == 2
		replace race_group = 2 if hispanic == 1
		replace race_group = 3 if Race2 == 4 | Race2 == 5
		label define race_groupl 0 "White" 1 "Black" 2 "Hispanic" 3 "Other"
		label values race_group race_groupl
				
* Save CO data into pooled dataset
	preserve
		rename Age age
		drop if fatal == .
		gen state = "CO"
		gen pool_ID = _n + 823
		keep state pool_ID fatal race_group male age age_cat mental_illness deadly_weap weapon_cat trauma_dum trauma_ord county metro urbanicity
		merge 1:1 pool_ID using "$pool\pooled_sample.dta"
		save "$pool\pooled_sample.dta", replace
	restore
	
* Collapse to the county level for map	
	collapse (sum) fatal nonfatal, by(county)
	
	gen total = fatal + nonfatal
	gen pfatal = (fatal/total)*100
	format pfatal %4.2f
	
* Figure S2: County-level fatality rates in Colorado
	gen state = 8
		
		maptile pfatal, geo(county2014) mapif(state==8) cutv(0 25 50 60 70 75) ///
		twopt(title("Colorado, 1/1/2010 - 6/30/2019", size(small) margin(top)) ///
		legend(pos(7) size(vsmall) label(2 "0%") label(3 "1-25%") label(4 "26-50%") label(5 "51-60%") label(6 "61-70%") label(7 "71-75%") label(8 ">75%") label(1 "No shootings") bmargin(0 0 0 0)) ///
		text(1.8 -0.5 ".", size(vhuge)) text(1.55 -0.2 "{bf:Denver}", size(vsmall)) ///
		text(.63 -0.36 ".", size(vhuge)) text(.6 -0.05 "{bf:Colorado Springs}", size(vsmall)) ///
		text(2.9 -0.68 ".", size(vhuge)) text(2.9 -0.9 "{bf:Fort Collins}", size(vsmall)) ///
		plotr(margin(14 5 5 5)) ///
		name(CO_tpfatal, replace))


**********
* IMPORT/CLEAN TEXAS AG DATA
	use "$texas\tx_ois_county_individuals", clear
	
	gen state = 48
	rename county county_name
	rename fips_code county // note one OIS occurred in NM (fips = 35037)
	rename incident_merge incident_id
	rename gender male
		
	gen fatal = 1 if death_inj == 1
	replace fatal = 0 if death_inj == 2
	
	gen nonfatal = 1 if fatal == 0
	replace nonfatal = 0 if fatal == 1
	
	tab race_ethnicity, m
	recode race_ethnicity (4 = 6)
		
	gen race_group = 0 if race_ethnicity == 1
	replace race_group = 1 if race_ethnicity == 2
	replace race_group = 2 if race_ethnicity == 3
	replace race_group = 3 if race_ethnicity == 5 | race_ethnicity == 6
	label define race_groupl 0 "White" 1 "Black" 2 "Hispanic" 3 "Other"
	label values race_group race_groupl
	
	gen weapon_cat = .
	replace weapon_cat = 1 if deadly_weap == 1
	replace weapon_cat = 3 if deadly_weap == 0
	label define weapon_catl 1 "deadly" 2 "toy/replica" 3 "unarmed" 4 "undetermined"
	label values weapon_cat weapon_catl
	
* merge in the age variable
	merge 1:1 case_id using "$texas\texas_ois_county_citizen_newer_age.dta", keepus(age)

	recode age (-99 = .)
	gen age_cat = .
	replace age_cat = 0 if age < 26
	replace age_cat = 1 if age >= 26 & age < 36
	replace age_cat = 2 if age >= 36 & age < 46
	replace age_cat = 3 if age >= 46
	replace age_cat = . if age == .
	label define agel 0 "25 and under" 1 "26-35" 2 "36-45" 3 "46+"
	label values age_cat agel
	tab age_cat
	
* merge in the Texas hospital data that John put together
	preserve
		import excel "$texas\tx_county_hospital.xlsx", sheet("Sheet1") firstrow clear
		rename fips county
		save "$texas\tx_county_hospital.dta", replace
	restore

	merge m:1 county using "$texas\tx_county_hospital.dta", gen(_merge2)
	
	gen trauma_dum = 1 if level1_dum == 1 | level2_dum == 1
	replace trauma_dum = 0 if level1_dum == 0 & level2_dum == 0
	
	egen trauma_count = rsum(total_level1 total_level2)
	tab trauma_count
	
	clonevar level1_ord = total_level1
	recode level1_ord (4 = 2) (3 = 2) // 0, 1, 2+
	
	gen trauma_ord = 0 if trauma_count == 0
	replace trauma_ord = 1 if trauma_count == 1
	replace trauma_ord = 2 if trauma_count == 2
	replace trauma_ord = 3 if trauma_count >= 3
	tab trauma_ord
	
	rename metro_non metro
	label define metrol 1 "Metropolitan Area" 0 "Non-metropolitan area"
	label values metro metrol
	tab metro
	
	gen urbanicity = 10 - rucc_2013 // see https://www.ers.usda.gov/data-products/rural-urban-continuum-codes/documentation/
	tab urbanicity 
	
* Save TX data into pooled dataset
	preserve
		drop if fatal == .
		rename state state2
		gen state = "TX"
		gen pool_ID = _n + 1227
		keep state pool_ID fatal race_group male age age_cat deadly_weap weapon_cat trauma_dum trauma_ord county metro urbanicity
		merge 1:1 pool_ID using "$pool\pooled_sample.dta", gen(_merge2)
		save "$pool\pooled_sample.dta", replace
	restore
	
* Collapse to the county level for map	
	collapse (sum) fatal nonfatal, by(county)
	
	gen total = fatal + nonfatal
	gen pfatal = (fatal/total)*100
	format pfatal %4.2f
	
* Figure S3: County-level fatality rates in Texas
	gen state = 48
		
		maptile pfatal, geo(county2014) mapif(state==48) cutv(0 25 50 60 70 75) ///
		twopt(title("Texas, 9/1/2015 - 12/31/2019", size(small) margin(top)) ///
		legend(pos(7) size(vsmall) label(2 "0%") label(3 "1-25%") label(4 "26-50%") label(5 "51-60%") label(6 "61-70%") label(7 "71-75%") label(8 ">75%") label(1 "No shootings") bmargin(0 0 0 0)) ///
		text(7.28 16.05 ".", size(vhuge)) text(7.15 16.5 "{bf:Dallas}", size(vsmall)) ///
		text(4.0 15.1 ".", size(vhuge)) text(4.0 15.3 "{bf:Austin}", size(vsmall)) ///
		text(3.3 17.5 ".", size(vhuge)) text(3.3 17.5 "{bf:Houston}", size(vsmall)) ///
		text(2.8 14.3 ".", size(vhuge)) text(2.3 13.18 "{bf:San Antonio}", size(vsmall)) ///
		text(6.07 6.35 ".", size(vhuge)) text(5.55 7.1 "{bf:El Paso}", size(vsmall)) ///
		plotr(margin(large)) ///
		name(TX_tpfatal, replace))


**********
* IMPORT/CLEAN CALIFORNIA URSUS DATA
* see https://openjustice.doj.ca.gov/data
* start with 2018 "civilian-officer" file from URSUS
	import delimited "$california\URSUS_Civilian-Officer_2018.csv", delimiter(comma) varnames(1) clear

* now import the 2016, 2017, and 2019 files, save as .dta, and merge with 2018 file
	preserve
		import delimited "$california\URSUS_Civilian-Officer_2016.csv", delimiter(comma) varnames(1) clear
		save "$california\URSUS_Civilian-Officer_2016.dta", replace
		
		import delimited "$california\URSUS_Civilian-Officer_2017.csv", delimiter(comma) varnames(1) clear
		save "$california\URSUS_Civilian-Officer_2017.dta", replace
		
		import excel using "$california\URSUS_Civilian-Officer_2019.xlsx", firstrow case(l) clear
		
	* some of the variables need to be converted so they match the 2016-18 format
		label define TF 1 "TRUE" 0 "FALSE"
		label val discharge_of_firearm_incident discharge_of_firearm_individual civilian_confirmed_armed received_force TF
		decode discharge_of_firearm_incident, gen(discharge_incident)
		decode discharge_of_firearm_individual, gen(discharge_individual)
		decode civilian_confirmed_armed, gen(armed)
		decode received_force, gen(received)
		drop discharge_of_firearm_incident discharge_of_firearm_individual civilian_confirmed_armed received_force
		rename discharge_incident discharge_of_firearm_incident
		rename discharge_individual discharge_of_firearm_individual
		rename armed civilian_confirmed_armed
		rename received received_force
		
		save "$california\URSUS_Civilian-Officer_2019.dta", replace
	restore
	
	merge m:m incident_id using "$california\URSUS_Civilian-Officer_2017.dta"
	merge m:m incident_id using "$california\URSUS_Civilian-Officer_2016.dta", force gen(_merge2)
	merge m:m incident_id using "$california\URSUS_Civilian-Officer_2019.dta", force gen(_merge3)
	
* save the merged file
	save "$california\URSUS_Civilian-Officer_2016-2019.dta", replace
	
* retain only:
	* fatal or injurious shootings,
	* where victim = civilian, 
	* and "received force" = true
	keep if civilian_officer == "Civilian" // n = 2990
	keep if discharge_of_firearm_individual == "TRUE" // n = 1254
	keep if received_force == "TRUE" // n = 1254
		gen MISS = 1 if regexm(received_force_type, "discharge_of_firearm_miss") == 1 // 241 misses
		replace MISS = 1 if MISS == . & received_force_type == "Discharge of firearm (miss)" // 309 individuals were shot at and (at least initially) missed
		replace MISS = 0 if MISS == 1 & regexm(received_force_type, "discharge_of_firearm_hit") == 1 // 47 missed initially but later hit, so these will be retained
	drop if MISS == 1 // n = 992
	drop if injury_level == "" // n = 989

	gen fatal = 1 if injury_level == "Death" | injury_level == "death"
	replace fatal = 0 if regexm(injury_level, "injury") == 1 | injury_level == "Injury"
	replace fatal = 0 if injured == "FALSE"
	
	gen nonfatal = 1 if fatal == 0
	replace nonfatal = 0 if fatal == 1
	
	gen male = 1 if gender == "Male" | gender == "male"
	replace male = 0 if gender == "Female" | gender == "female"
	
	gen race = 1 if race_ethnic_group == "White" | race_ethnic_group == "white"
	replace race = 2 if race_ethnic_group == "Black" | race_ethnic_group == "black"
	replace race = 3 if regexm(race_ethnic_group, "Hispanic") == 1 | ///
		regexm(race_ethnic_group, "hispanic") == 1
	replace race = 4 if race_ethnic_group == "Asian / Pacific Islander" | ///
		race_ethnic_group == "asian" | ///
		race_ethnic_group == "hawaiian_islander"
	replace race = 5 if race_ethnic_group == "American Indian" | ///
		race_ethnic_group == "Black, White, Other" | ///
		race_ethnic_group == "Other" | ///
		race_ethnic_group == "american_indian" | ///
		race_ethnic_group == "asian_indian" | ///
		race_ethnic_group == "black, hawaiian_islander" | ///
		race_ethnic_group == "black, white" | ///
		race_ethnic_group == "other" | ///
		race_ethnic_group == "white, hawaiian_islander"
						
	gen race_group = 0 if race == 1
	replace race_group = 1 if race == 2
	replace race_group = 2 if race == 3
	replace race_group = 3 if race == 4 | race == 5
	label define race_groupl 0 "White" 1 "Black" 2 "Hispanic" 3 "Other"
	label values race_group race_groupl
	
	tab age
	gen age_cat = .
	replace age_cat = 0 if regexm(age, "17") == 1
	replace age_cat = 0 if regexm(age, "18") == 1
	replace age_cat = 0 if regexm(age, "21") == 1
	replace age_cat = 1 if regexm(age, "26") == 1
	replace age_cat = 1 if regexm(age, "31") == 1
	replace age_cat = 2 if regexm(age, "36") == 1
	replace age_cat = 2 if regexm(age, "41") == 1
	replace age_cat = 3 if regexm(age, "46") == 1
	replace age_cat = 3 if regexm(age, "51") == 1
	replace age_cat = 3 if regexm(age, "56") == 1
	replace age_cat = 3 if regexm(age, "61") == 1
	replace age_cat = 3 if regexm(age, "66") == 1
	replace age_cat = 3 if regexm(age, "71") == 1
	replace age_cat = 3 if regexm(age, "86") == 1
	label define agel 0 "25 and under" 1 "26-35" 2 "36-45" 3 "46+"
	label values age_cat agel
	
	gen mental_illness = 1 if regexm(civilian_signs_impairment_disabi, "mental") ==1
	replace mental_illness = 0 if mental_illness != 1
	
	gen wound = 0
	replace wound = 1 if regexm(received_force_location, "head") == 1
	replace wound = 1 if regexm(received_force_location, "Head") == 1
	replace wound = 1 if regexm(received_force_location, "neck") == 1
	replace wound = 1 if regexm(received_force_location, "Neck") == 1
	replace wound = 1 if regexm(received_force_location, "throat") == 1
	replace wound = 1 if regexm(received_force_location, "Throat") == 1
	replace wound = 1 if regexm(received_force_location, "chest") == 1
	replace wound = 1 if regexm(received_force_location, "Chest") == 1
	replace wound = . if received_force_location == "(Not applicable)"
	label define woundl 1 "Head/Neck/Chest" 0 "All else"
	label values wound woundl
	
	gen deadly_weap = 1 if civilian_confirmed_armed == "TRUE"
	replace deadly_weap = 0 if civilian_confirmed_armed == "FALSE"
							   
	gen weapon_cat = 1 if deadly_weap == 1
	replace weapon_cat = 2 if civilian_confirmed_armed_weapon == "Firearm replica" | ///
							   civilian_confirmed_armed_weapon == "firearm_replica"
	replace weapon_cat = 3 if civilian_confirmed_armed == "FALSE"
	
	gen deadly_weap_alt = 1 if civilian_perceived_armed == "TRUE" | civilian_confirmed_armed == "TRUE"
	replace deadly_weap_alt = 0 if civilian_perceived_armed == "FALSE" & civilian_confirmed_armed == "FALSE"
	
* import the "incident" files for each year, save as .dta, and merge with the master file
	preserve
		import delimited "$california\URSUS_Incident_2016.csv", delimiter(comma) varnames(1) clear
		save "$california\URSUS_Incident_2016.dta", replace
		
		import delimited "$california\URSUS_Incident_2017.csv", delimiter(comma) varnames(1) clear
		save "$california\URSUS_Incident_2017.dta", replace
	
		import delimited "$california\URSUS_Incident_2018.csv", delimiter(comma) varnames(1) clear
		save "$california\URSUS_Incident_2018.dta", replace
		
		import excel using "$california\URSUS_Incident_2019.xlsx", firstrow case(l) clear
		save "$california\URSUS_Incident_2019.dta", replace
		
		merge 1:1 incident_id using "$california\URSUS_Incident_2016.dta", force nogen
		merge 1:1 incident_id using "$california\URSUS_Incident_2017.dta", force nogen
		merge 1:1 incident_id using "$california\URSUS_Incident_2018.dta", force nogen
		
		save "$california\URSUS_Incident_2016-19.dta", replace
	restore
	
	merge m:1 incident_id using "$california\URSUS_Incident_2016-19.dta", gen(_merge4)
	
	drop _merge*
	
* county field needs to be cleaned
	tab county
	gen county_lower = lower(county)
	drop county
	rename county_lower county
	gen county2 = ""
	replace county2 = "Alameda" if regexm(county, "alameda") == 1
	replace county2 = "Butte" if regexm(county, "butte") == 1
	replace county2 = "Calaveras" if regexm(county, "calaveras") == 1
	replace county2 = "Contra Costa" if regexm(county, "contra costa") == 1
	replace county2 = "Del Norte" if regexm(county, "del norte") == 1
	replace county2 = "El Dorado" if regexm(county, "el dorado") == 1
	replace county2 = "Fresno" if regexm(county, "fresno") == 1
	replace county2 = "Glenn" if regexm(county, "glenn") == 1
	replace county2 = "Humboldt" if regexm(county, "humboldt") == 1
	replace county2 = "Imperial" if regexm(county, "imperial") == 1
	replace county2 = "Inyo" if regexm(county, "inyo") == 1
	replace county2 = "Kern" if regexm(county, "kern") == 1
	replace county2 = "Kings" if regexm(county, "kings") == 1
	replace county2 = "Lake" if regexm(county, "lake") == 1
	replace county2 = "Lassen" if regexm(county, "lassen") == 1
	replace county2 = "Los Angeles" if regexm(county, "los angeles") == 1
	replace county2 = "Madera" if regexm(county, "madera") == 1
	replace county2 = "Marin" if regexm(county, "marin") == 1
	replace county2 = "Mariposa" if regexm(county, "mariposa") == 1
	replace county2 = "Mendocino" if regexm(county, "mendocino") == 1
	replace county2 = "Merced" if regexm(county, "merced") == 1
	replace county2 = "Modoc" if regexm(county, "modoc") == 1
	replace county2 = "Monterey" if regexm(county, "monterey") == 1
	replace county2 = "Napa" if regexm(county, "napa") == 1
	replace county2 = "Nevada" if regexm(county, "nevada") == 1
	replace county2 = "Orange" if regexm(county, "orange") == 1
	replace county2 = "Placer" if regexm(county, "placer") == 1
	replace county2 = "Plumas" if regexm(county, "plumas") == 1
	replace county2 = "Riverside" if regexm(county, "riverside") == 1
	replace county2 = "Sacramento" if regexm(county, "sacramento") == 1
	replace county2 = "San Benito" if regexm(county, "san benito") == 1
	replace county2 = "San Bernardino" if regexm(county, "san bernardino") == 1
	replace county2 = "San Diego" if regexm(county, "san diego") == 1
	replace county2 = "San Francisco" if regexm(county, "san francisco") == 1
	replace county2 = "San Joaquin" if regexm(county, "san joaquin") == 1
	replace county2 = "San Luis Obispo" if regexm(county, "san luis obispo") == 1
	replace county2 = "San Mateo" if regexm(county, "san mateo") == 1
	replace county2 = "Santa Barbara" if regexm(county, "santa barbara") == 1
	replace county2 = "Santa Clara" if regexm(county, "santa clara") == 1
	replace county2 = "Santa Cruz" if regexm(county, "santa cruz") == 1
	replace county2 = "Shasta" if regexm(county, "shasta") == 1
	replace county2 = "Siskiyou" if regexm(county, "siskiyou") == 1
	replace county2 = "Solano" if regexm(county, "solano") == 1
	replace county2 = "Sonoma" if regexm(county, "sonoma") == 1
	replace county2 = "Stanislaus" if regexm(county, "stanislaus") == 1
	replace county2 = "Sutter" if regexm(county, "sutter") == 1
	replace county2 = "Tehama" if regexm(county, "tehama") == 1
	replace county2 = "Trinity" if regexm(county, "trinity") == 1
	replace county2 = "Tulare" if regexm(county, "tulare") == 1
	replace county2 = "Tuolumne" if regexm(county, "tuolumne") == 1
	replace county2 = "Ventura" if regexm(county, "ventura") == 1
	replace county2 = "Yolo" if regexm(county, "yolo") == 1
	replace county2 = "Yuba" if regexm(county, "yuba") == 1
	
	tab county2
	rename county2 county_name
	drop county 
	
* merge in other CA counties that didn't have shootings from 2016-18
* see https://www.nrcs.usda.gov/wps/portal/nrcs/detail/ca/home/?cid=nrcs143_013697
	preserve
		import excel "$california\List of Counties in CA.xlsx", firstrow clear
		save "$california\List of Counties in CA.dta", replace
	restore
	
	merge m:1 county_name using "$california\List of Counties in CA.dta"
	
	tab county_name if _merge == 2 // * note Alpine, Amador, Colusa, Mono, & Sierra are the only counties that didn't submit anything to URSUS

* merge in CA hospital data that John put together
	preserve
		import excel "$california\ca_county_hospital.xlsx", sheet("Sheet1") firstrow clear
		rename fips county
		drop if county_name == ""
		save "$california\ca_county_hospital.dta", replace
	restore

	merge m:1 county using "$california\ca_county_hospital.dta", gen(_merge2)
	
	gen trauma_dum = 1 if level1_dum == 1 | level2_dum == 1
	replace trauma_dum = 0 if level1_dum == 0 & level2_dum == 0
	
	egen trauma_count = rsum(total_level1 total_level2)
	tab trauma_count
	
	clonevar level1_ord = total_level1
	recode level1_ord (4 = 2) // 0, 1, 2+
	
	gen trauma_ord = 0 if trauma_count == 0
	replace trauma_ord = 1 if trauma_count == 1
	replace trauma_ord = 2 if trauma_count == 2
	replace trauma_ord = 3 if trauma_count >= 3
	tab trauma_ord
	
	rename metro_non metro
	label define metrol 1 "Metropolitan Area" 0 "Non-metropolitan area"
	label values metro metrol
	tab metro
	
	gen urbanicity = 10 - rucc_2013 // see https://www.ers.usda.gov/data-products/rural-urban-continuum-codes/documentation/
	tab urbanicity 

	
* Save CA data into pooled dataset		
	preserve
		drop if fatal == .
		rename state state2
		gen state = "CA"
		gen pool_ID = _n + 1979
		keep state pool_ID fatal race_group wound male age_cat mental_illness deadly_weap deadly_weap_alt weapon_cat trauma_dum trauma_ord county metro urbanicity
		merge 1:1 pool_ID using "$pool\pooled_sample.dta", gen(_merge3)
		save "$pool\pooled_sample.dta", replace
	restore

* Collapse to the county level for map	
	collapse (sum) fatal nonfatal, by(county)
	
	gen total = fatal + nonfatal
	gen pfatal = (fatal/total)*100
	format pfatal %4.2f
	
* Figure S4: county-level fatality rates in California
	gen state = 6
		
		maptile pfatal, geo(county2014) mapif(state==6) cutv(0 25 50 60 70 75) ///
		twopt(title("California, 1/1/2016 - 12/31/2019", size(small) margin(top)) ///
		legend(pos(7) size(vsmall) label(2 "0%") label(3 "1-25%") label(4 "26-50%") label(5 "51-60%") label(6 "61-70%") label(7 "71-75%") label(8 ">75%") label(1 "No shootings") bmargin(0 0 0 0)) ///
		text(-12.30 -24.00 ".", size(vhuge)) text(-12.6 -23.2 "{bf:Sacramento}", size(vsmall)) ///
		text(-13.40 -25.03 ".", size(vhuge)) text(-13.47 -24.28 "{bf:San Francisco}", size(vsmall)) ///
		text(-13.90 -24.40 ".", size(vhuge)) text(-14.6 -24.5 "{bf:San Jose}", size(vsmall)) ///
		text(-14.80 -22.30 ".", size(vhuge)) text(-15.2 -21.75 "{bf:Fresno}", size(vsmall)) ///
		text(-18.50 -20.80 ".", size(vhuge)) text(-18.5 -20.2 "{bf:Los Angeles}", size(vsmall)) ///
		text(-20.25 -19.65 ".", size(vhuge)) text(-20.25 -19.25 "{bf:San Diego}", size(vsmall)) ///
		plotr(margin(large)) ///
		name(CA_tpfatal, replace))
		
		
* ######################################## ANALYSES ################################################### *

* IMPORT POOLED DATA (Thanks for the suggestion, Reviewer #2!)

use "$pool\pooled_sample.dta", clear

	gen stateFE = 0 if state == "FL"
	replace stateFE = 1 if state == "CO"
	replace stateFE = 2 if state == "TX"
	replace stateFE = 3 if state == "CA"
	label define stateFEl 0 "Florida" 1 "Colorado" 2 "Texas" 3 "California"
	label values stateFE stateFEl
	tab stateFE

***
log using "$output\results", replace

* Figure 1: Fatal & injurious shootings in each state	
	gen nonfatal = 1 if fatal == 0
	replace nonfatal = 0 if fatal == 1

	graph bar (sum) fatal nonfatal, over(stateFE) ///
		leg(pos(6) size(small) rows(1) label(1 "Fatal") label(2 "Injurious")) ///
		blabel(total, pos(outside) size(vsmall))
	
* drop a Texas shooting that occurred in New Mexico (missing on Trauma variable)
	drop if pool_ID == 1228 // original case_id in Texas file = 198
	
* Table 1, Model 1: Race only for Pooled Sample
	logit fatal i.race_group, cluster(county) cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(race_group) cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	
* Table 1, Model 2: Full model for Pooled Sample
	logit fatal i.race_group i.male i.age_cat i.deadly_weap i.trauma_dum i.metro i.stateFE, cluster(county) cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	est tab, p(%12.10g)
	margins race_group, atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	
	* Figure 4: Adjusted predictions for Pr(Fatal) by race/ethnicity
		marginsplot, recast(scatter) ytitle("Pr(Fatal)", size(small)) yscale(range(.4(.1).8)) ylabel(.4(.1).8, labs(small)) xlabel(,labs(small)) xtitle("") title("") 
	
	margins, dydx(race_group) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(male) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(age_cat) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(deadly_weap) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(trauma_dum) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(metro) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(stateFE) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	
	collin fatal race_group male age_cat deadly_weap trauma_dum metro stateFE
	
* Table S1: Proportion of covariates that were fatal and nonfatal in each state
	tab race_group fatal if stateFE==0, row m
	tab race_group fatal if stateFE==1, row m
	tab race_group fatal if stateFE==2, row m
	tab race_group fatal if stateFE==3, row m
	
	tab male fatal if stateFE==0, row m
	tab male fatal if stateFE==1, row m
	tab male fatal if stateFE==2, row m
	tab male fatal if stateFE==3, row m
	
	tab age_cat fatal if stateFE==0, row m
	tab age_cat fatal if stateFE==1, row m
	tab age_cat fatal if stateFE==2, row m
	tab age_cat fatal if stateFE==3, row m
	
	tab weapon_cat fatal if stateFE==0, row m
	tab weapon_cat fatal if stateFE==1, row m
	tab weapon_cat fatal if stateFE==2, row m
	tab weapon_cat fatal if stateFE==3, row m
	
	tab trauma_dum fatal if stateFE==0, row m
	tab trauma_dum fatal if stateFE==1, row m
	tab trauma_dum fatal if stateFE==2, row m
	tab trauma_dum fatal if stateFE==3, row m
	
	tab metro fatal if stateFE==0, row m
	tab metro fatal if stateFE==1, row m
	tab metro fatal if stateFE==2, row m
	tab metro fatal if stateFE==3, row m
	
	tab mental_illness fatal if stateFE==0, row m
	tab mental_illness fatal if stateFE==1, row m
	tab mental_illness fatal if stateFE==3, row m
	
	tab wound fatal if stateFE==3, row m
	
* Table S2: Ordinal Trauma Care & continuous urbanicity variables for Pooled Sample
	logit fatal i.race_group i.male i.age_cat i.deadly_weap i.trauma_ord urbanicity i.stateFE, cluster(county) cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins race_group, atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	marginsplot, recast(scatter) ytitle("Pr(Fatal)", size(small)) yscale(range(.4(.1).8)) ylabel(.4(.1).8, labs(small)) xlabel(,labs(small)) xtitle("") title("")
	margins, dydx(race_group) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(male) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(age_cat) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(deadly_weap) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(trauma_ord) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(urbanicity) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(stateFE) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)

* Table S3, Model 1: Race only for Florida
	logit fatal i.race_group if stateFE ==0, cluster(county) cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(race_group) cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	
* Table S3, Model 2: Full model for Florida
	logit fatal i.race_group i.male c.age i.mental_illness i.deadly_weap i.trauma_dum i.metro if stateFE ==0, cluster(county) cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	est tab, p(%12.10g)
	margins, dydx(race_group) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(male) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(age) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(mental_illness) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(deadly_weap) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(trauma_dum) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(metro) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	
* Table S4, Model 1: Race only for Colorado
	logit fatal i.race_group if stateFE ==1, asis cluster(county) cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(race_group) cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	
* Table S4, Model 2: Full model for Colorado
	logit fatal i.race_group i.male c.age i.mental_illness i.deadly_weap i.trauma_dum i.metro if stateFE ==1, asis cluster(county) cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	est tab, p(%12.10g)
	margins, dydx(race_group) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(male) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(age) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(mental_illness) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(deadly_weap) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(trauma_dum) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(metro) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	
* Table S5, Model 1: Race only for Texas
	logit fatal i.race_group if stateFE ==2, cluster(county) cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(race_group) cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	
* Table S5, Model 2: Full model for Texas
	logit fatal i.race_group i.male c.age i.deadly_weap i.trauma_dum i.metro if stateFE ==2, cluster(county) cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	est tab, p(%12.10g)
	margins, dydx(race_group) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(male) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(age) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(deadly_weap) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(trauma_dum) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(metro) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	
* Table S6, Model 1: Race only for California
	logit fatal i.race_group if stateFE ==3, cluster(county) cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(race_group) cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	
* Table S6, Model 2: Full model for California
	logit fatal i.race_group i.male i.wound i.age_cat i.mental_illness i.deadly_weap_alt i.trauma_dum i.metro if stateFE ==3, cluster(county) cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	est tab, p(%12.10g)
	margins, dydx(race_group) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(male) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(wound) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(age_cat) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(mental_illness) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(deadly_weap_alt) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(trauma_dum) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	margins, dydx(metro) atmeans cformat(%4.3f) sformat(%4.3f) pformat(%4.3f)
	
log close
***
	
* Figure 2: Racial disparities in each state
* Note: Florida population estimates are 2010-14 ACS 5-year estimates; other states are 2015-19 ACS 5-year estimates

	clear
	set obs 16

	gen state = .
	replace state = 1 in 1/4
	replace state = 2 in 5/8
	replace state = 3 in 9/12
	replace state = 4 in 13/16
	label define statel 1 "Florida" 2 "Colorado" 3 "Texas" 4 "California"
	label values state statel

	gen data = 1 if mod(_n, 4) == 1
	replace data = 2 if mod(_n+3, 4) == 1
	replace data = 3 if mod((_n+2), 4) == 1
	replace data = 4 if mod((_n+1), 4) == 1
	label define datal 1 "Fatal Shootings" 2 "Injurious Shootings" 3 "Combined Shootings" 4 "Population*"
	label values data datal

	gen pct_white = .
	gen pct_black = .
	gen pct_hisp  = .
	format pct_* %4.2f

	replace pct_white = .45 if state == 1 & data == 1
	replace pct_white = .34 if state == 1 & data == 2
	replace pct_white = .40 if state == 1 & data == 3
	replace pct_white = .57 if state == 1 & data == 4

	replace pct_white = .55 if state == 2 & data == 1
	replace pct_white = .50 if state == 2 & data == 2
	replace pct_white = .53 if state == 2 & data == 3
	replace pct_white = .68 if state == 2 & data == 4

	replace pct_white = .40 if state == 3 & data == 1
	replace pct_white = .34 if state == 3 & data == 2
	replace pct_white = .37 if state == 3 & data == 3
	replace pct_white = .42 if state == 3 & data == 4

	replace pct_white = .32 if state == 4 & data == 1
	replace pct_white = .30 if state == 4 & data == 2
	replace pct_white = .31 if state == 4 & data == 3
	replace pct_white = .37 if state == 4 & data == 4

	replace pct_black = .37 if state == 1 & data == 1
	replace pct_black = .47 if state == 1 & data == 2
	replace pct_black = .42 if state == 1 & data == 3
	replace pct_black = .15 if state == 1 & data == 4

	replace pct_black = .10 if state == 2 & data == 1
	replace pct_black = .16 if state == 2 & data == 2
	replace pct_black = .12 if state == 2 & data == 3
	replace pct_black = .04 if state == 2 & data == 4

	replace pct_black = .22 if state == 3 & data == 1
	replace pct_black = .32 if state == 3 & data == 2
	replace pct_black = .27 if state == 3 & data == 3
	replace pct_black = .12 if state == 3 & data == 4

	replace pct_black = .16 if state == 4 & data == 1
	replace pct_black = .19 if state == 4 & data == 2
	replace pct_black = .17 if state == 4 & data == 3
	replace pct_black = .06 if state == 4 & data == 4

	replace pct_hisp  = .17 if state == 1 & data == 1
	replace pct_hisp  = .14 if state == 1 & data == 2
	replace pct_hisp  = .16 if state == 1 & data == 3
	replace pct_hisp  = .23 if state == 1 & data == 4

	replace pct_hisp  = .31 if state == 2 & data == 1
	replace pct_hisp  = .31 if state == 2 & data == 2
	replace pct_hisp  = .31 if state == 2 & data == 3
	replace pct_hisp  = .22 if state == 2 & data == 4

	replace pct_hisp  = .34 if state == 3 & data == 1
	replace pct_hisp  = .33 if state == 3 & data == 2
	replace pct_hisp  = .33 if state == 3 & data == 3
	replace pct_hisp  = .39 if state == 3 & data == 4

	replace pct_hisp  = .45 if state == 4 & data == 1
	replace pct_hisp  = .45 if state == 4 & data == 2
	replace pct_hisp  = .45 if state == 4 & data == 3
	replace pct_hisp  = .39 if state == 4 & data == 4

	* B-W and H-W Disparities as Odds Ratios

	gen bw_disp = .
	gen hw_disp =.
	format *_disp %4.2f

	* Florida
		replace bw_disp = (pct_black[1] / pct_black[4]) / (pct_white[1] / pct_white[4]) if state == 1 & data == 1
		replace bw_disp = (pct_black[2] / pct_black[4]) / (pct_white[2] / pct_white[4]) if state == 1 & data == 2
		replace bw_disp = (pct_black[3] / pct_black[4]) / (pct_white[3] / pct_white[4]) if state == 1 & data == 3

		replace hw_disp = (pct_hisp[1] / pct_hisp[4]) / (pct_white[1] / pct_white[4]) if state == 1 & data == 1
		replace hw_disp = (pct_hisp[2] / pct_hisp[4]) / (pct_white[2] / pct_white[4]) if state == 1 & data == 2
		replace hw_disp = (pct_hisp[3] / pct_hisp[4]) / (pct_white[3] / pct_white[4]) if state == 1 & data == 3

	* Colorado
		replace bw_disp = (pct_black[5] / pct_black[8]) / (pct_white[5] / pct_white[8]) if state == 2 & data == 1
		replace bw_disp = (pct_black[6] / pct_black[8]) / (pct_white[6] / pct_white[8]) if state == 2 & data == 2
		replace bw_disp = (pct_black[7] / pct_black[8]) / (pct_white[7] / pct_white[8]) if state == 2 & data == 3

		replace hw_disp = (pct_hisp[5] / pct_hisp[8]) / (pct_white[5] / pct_white[8]) if state == 2 & data == 1
		replace hw_disp = (pct_hisp[6] / pct_hisp[8]) / (pct_white[6] / pct_white[8]) if state == 2 & data == 2
		replace hw_disp = (pct_hisp[7] / pct_hisp[8]) / (pct_white[7] / pct_white[8]) if state == 2 & data == 3

	* Texas
		replace bw_disp = (pct_black[9] / pct_black[12]) / (pct_white[9] / pct_white[4]) if state == 3 & data == 1
		replace bw_disp = (pct_black[10] / pct_black[12]) / (pct_white[10] / pct_white[4]) if state == 3 & data == 2
		replace bw_disp = (pct_black[11] / pct_black[12]) / (pct_white[11] / pct_white[4]) if state == 3 & data == 3

		replace hw_disp = (pct_hisp[9] / pct_hisp[12]) / (pct_white[9] / pct_white[12]) if state == 3 & data == 1
		replace hw_disp = (pct_hisp[10] / pct_hisp[12]) / (pct_white[10] / pct_white[12]) if state == 3 & data == 2
		replace hw_disp = (pct_hisp[11] / pct_hisp[12]) / (pct_white[11] / pct_white[12]) if state == 3 & data == 3

	* California
		replace bw_disp = (pct_black[13] / pct_black[16]) / (pct_white[13] / pct_white[16]) if state == 4 & data == 1
		replace bw_disp = (pct_black[14] / pct_black[16]) / (pct_white[14] / pct_white[16]) if state == 4 & data == 2
		replace bw_disp = (pct_black[15] / pct_black[16]) / (pct_white[15] / pct_white[16]) if state == 4 & data == 3

		replace hw_disp = (pct_hisp[13] / pct_hisp[16]) / (pct_white[13] / pct_white[16]) if state == 4 & data == 1
		replace hw_disp = (pct_hisp[14] / pct_hisp[16]) / (pct_white[14] / pct_white[16]) if state == 4 & data == 2
		replace hw_disp = (pct_hisp[15] / pct_hisp[16]) / (pct_white[15] / pct_white[16]) if state == 4 & data == 3


	graph hbar bw_disp hw_disp if state == 1 & bw_disp != ., over(data, lab(labs(vsmall))) ///
		leg(pos(6) size(small) rows(1) label(1 "Black") label(2 "Hispanic")) ///
		blabel(total, pos(outside) size(vsmall) format(%4.2f)) ///
		title("Florida, 2009-14", size(small)) yline(1, lp(solid)) ///
		graphr(margin(0 0 0 0)) plotr(margin(1 2 0 0)) ///
		ytitle("Risk Relative to Whites", size(vsmall)) ///
		yscale(range(0(1)6)) ylabel(0(1)6) ///
		name(FL, replace) nodraw

	graph hbar bw_disp hw_disp if state == 2 & bw_disp != ., over(data, lab(labs(vsmall))) ///
		leg(pos(6) size(small) rows(1) label(1 "Black") label(2 "Hispanic")) ///
		blabel(total, pos(outside) size(vsmall) format(%4.2f)) ///
		title("Colorado, 2010-19", size(small)) yline(1, lp(solid)) ///
		graphr(margin(0 0 0 0)) plotr(margin(2 1 0 0)) ///
		ytitle("Risk Relative to Whites", size(vsmall)) ///
		yscale(range(0(1)6)) ylabel(0(1)6) ///
		name(CO, replace) nodraw
		
	graph hbar bw_disp hw_disp if state == 3 & bw_disp != ., over(data, lab(labs(vsmall))) ///
		leg(pos(6) size(small) rows(1) label(1 "Black") label(2 "Hispanic")) ///
		blabel(total, pos(outside) size(vsmall) format(%4.2f)) ///
		title("Texas, 2015-19", size(small)) yline(1, lp(solid)) ///
		graphr(margin(0 0 0 0)) plotr(margin(1 2 0 0)) ///
		ytitle("Risk Relative to Whites", size(vsmall)) ///
		yscale(range(0(1)6)) ylabel(0(1)6) ///
		name(TX, replace) nodraw
		
	graph hbar bw_disp hw_disp if state == 4 & bw_disp != ., over(data, lab(labs(vsmall))) ///
		leg(pos(6) size(small) rows(1) label(1 "Black") label(2 "Hispanic")) ///
		blabel(total, pos(outside) size(vsmall) format(%4.2f)) ///
		title("California, 2016-19", size(small)) yline(1, lp(solid)) ///
		graphr(margin(0 0 0 0)) plotr(margin(1 2 0 0)) ///
		ytitle("Risk Relative to Whites", size(vsmall)) ///
		yscale(range(0(1)6)) ylabel(0(1)6) ///
		name(CA, replace) nodraw

	graph combine FL CO TX CA, rows(2) 
	

* Figure 3: Dot plot showing proportion of shootings that were fatal across each covariate in each state for pooled sample analysis
* So this figure just plots %fatal by state for each row from Table S1 (minus the "undetermined" rows)
	clear
	set obs 76

	gen florida = .
	replace florida = 1 in 1/19
	gen colorado = .
	replace colorado = 1 in 20/38
	gen texas = .
	replace texas = 1 in 39/57
	gen cali = .
	replace cali = 1 in 58/76

	gen cell = 1 if mod(_n, 19) == 1
	replace cell =  2 if mod((_n+18), 19) == 1
	replace cell =  3 if mod((_n+17), 19) == 1
	replace cell =  4 if mod((_n+16), 19) == 1
	replace cell =  5 if mod((_n+15), 19) == 1
	replace cell =  6 if mod((_n+14), 19) == 1
	replace cell =  7 if mod((_n+13), 19) == 1
	replace cell =  8 if mod((_n+12), 19) == 1
	replace cell =  9 if mod((_n+11), 19) == 1
	replace cell = 10 if mod((_n+10), 19) == 1
	replace cell = 11 if mod((_n+9), 19) == 1
	replace cell = 12 if mod((_n+8), 19) == 1
	replace cell = 13 if mod((_n+7), 19) == 1
	replace cell = 14 if mod((_n+6), 19) == 1
	replace cell = 15 if mod((_n+5), 19) == 1
	replace cell = 16 if mod((_n+4), 19) == 1
	replace cell = 17 if mod((_n+3), 19) == 1
	replace cell = 18 if mod((_n+2), 19) == 1
	replace cell = 19 if mod((_n+1), 19) == 1
	label define celll 1 "Overall" 2 "White" 3 "Black" 4 "Hispanic" 5 "Asian" 6 "Other Race" ///
		7 "Male" 8 "Female" ///
		9 "Age <= 25" 10 "Age 26-35" 11 "Age 36-45" 12 "Age 46+" ///
		13 "Deadly Weapon" 14 "Toy/BB Gun" 15 "Unarmed"  ///
		16 "Trauma Center" 17 "No Trauma Center" ///
		18 "Metro County" 19 "Non-metro County"
	label values cell celll
	tab cell

	replace florida = .54 in 1
	replace florida = .61 in 2
	replace florida = .48 in 3
	replace florida = .59 in 4
	replace florida = .67 in 5
	replace florida = .00 in 6
	replace florida = .55 in 7
	replace florida = .48 in 8
	replace florida = .41 in 9
	replace florida = .55 in 10
	replace florida = .60 in 11
	replace florida = .69 in 12
	replace florida = .57 in 13
	replace florida = .60 in 14
	replace florida = .43 in 15
	replace florida = .52 in 16
	replace florida = .70 in 17
	replace florida = .54 in 18
	replace florida = .72 in 19

	replace colorado = .63 in 20
	replace colorado = .65 in 21
	replace colorado = .51 in 22
	replace colorado = .63 in 23
	replace colorado = 1.0 in 24
	replace colorado = 1.0 in 25
	replace colorado = .64 in 26
	replace colorado = .35 in 27
	replace colorado = .58 in 28
	replace colorado = .59 in 29
	replace colorado = .70 in 30
	replace colorado = .68 in 31
	replace colorado = .64 in 32
	replace colorado = . in 33
	replace colorado = .43 in 34
	replace colorado = .63 in 35
	replace colorado = .65 in 36
	replace colorado = .63 in 37
	replace colorado = .69 in 38

	replace texas = .53 in 39
	replace texas = .57 in 40
	replace texas = .44 in 41
	replace texas = .54 in 42
	replace texas = .70 in 43
	replace texas = .83 in 44
	replace texas = .52 in 45
	replace texas = .57 in 46
	replace texas = .44 in 47
	replace texas = .53 in 48
	replace texas = .58 in 49
	replace texas = .59 in 50
	replace texas = .56 in 51
	replace texas = . in 52
	replace texas = .35 in 53
	replace texas = .51 in 54
	replace texas = .56 in 55
	replace texas = .52 in 56
	replace texas = .60 in 57

	replace cali = .56 in 58
	replace cali = .57 in 59
	replace cali = .51 in 60
	replace cali = .55 in 61
	replace cali = .67 in 62
	replace cali = .51 in 63
	replace cali = .56 in 64
	replace cali = .44 in 65
	replace cali = .46 in 66
	replace cali = .57 in 67
	replace cali = .58 in 68
	replace cali = .65 in 69
	replace cali = .59 in 70
	replace cali = .63 in 71
	replace cali = .39 in 72
	replace cali = .56 in 73
	replace cali = .51 in 74
	replace cali = .56 in 75
	replace cali = .50 in 76

	graph dot florida colorado texas cali, over(cell) ///
		yscale(range(0(.1)1)) ylabel(0(.1)1) ///
		leg(pos(6) size(small) rows(1) label(1 "Florida") label(2 "Colorado") label(3 "Texas") label(4 "California"))
