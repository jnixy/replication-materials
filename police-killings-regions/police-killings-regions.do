* How many police-involved deaths occur each year in the United States?
* Updated 2/18/2021

import delimited "https://raw.githubusercontent.com/jwirfs-brock/MWNB-police-killings/main/US-police-killings.csv", clear

clonevar FE = countfatalities if source == "FE"
clonevar FE_NV = countfatalities if source == "FE_NV"
clonevar Guard = countfatalities if source == "Guardian"
clonevar MPV = countfatalities if source == "MPV"
clonevar WAPO = countfatalities if source == "WaPo"

collapse (sum) FE* Guard MPV WAPO (mean) population, by(year)

gen FE_V = FE - FE_NV

local source "FE FE_NV FE_V Guard MPV WAPO"
foreach i in `source' {
	gen `i'_cap = (`i'/population)*1000000
	}
	
recode Guard* MPV* WAPO* (0 = .)

* Plot FE v. MPV v. WAPO by year
	line FE year, lc("27 158 119") lw(medthick) ///
	|| line MPV year, lc("217 95 2") lw(medthick) ///
	|| line WAPO year, lc("117 112 179") lw(medthick) ///
	title("People Killed by U.S. Police Officers", size(small)) ///
	subtitle("According to 3 Separate Datasets", size(vsmall)) ///
	legend(pos(6) size(small) rows(1) label(1 "Fatal Encounters") label(2 "Mapping Police Violence") label(3 "Washington Post")) ///
	plotr(fc(gs16) lc(gs8)) ///
	yla(0(200)2000, labs(vsmall)) yscale(range(0(200)2050)) ytitle("") ///
	xla(2000(1)2020, labs(vsmall) angle(45) nogrid) xscale(range(2000(1)2020)) xtitle("") ///
	name(years, replace)

* For FE, plot Vehicular v. Non-vehicular
	line FE_NV year, lc("27 158 119") lw(medthick) ///
	|| line FE_V year, lc("117 112 179") lw(medthick) ///
	title("People Killed by U.S. Police Officers", size(small)) ///
	subtitle("By Cause of Death", size(vsmall)) ///
	legend(pos(6) size(vsmall) rows(1) label(1 "Non-Vehicular") label(2 "Vehicular")) ///
	plotr(fc(gs16) lc(gs8)) ///
	yla(0(200)1600, labs(vsmall)) yscale(range(0(200)1600)) ytitle("") ///
	xla(2000(1)2020, labs(vsmall) angle(45) nogrid) xscale(range(2000(1)2020)) xtitle("") ///
	name(fe_split, replace)


	
	
* Import regional data
import delimited "https://raw.githubusercontent.com/jwirfs-brock/MWNB-police-killings/main/regions-police-killings.csv", clear

encode division, gen(Division)

forval num = 1/9 {
	gen FEdeaths_`num' = countfatalities if source == "FE" & Division == `num'
	gen FE_NVdeaths_`num' = countfatalities if source == "FE_NV" & Division == `num'
	gen FEdeathsPM_`num' = permillion if source == "FE" & Division == `num'
	gen FE_NVdeathsPM_`num' = permillion if source == "FE_NV" & Division == `num'
	}	
	
collapse (sum) FE* (mean)population, by(year)

forval num = 1/9 {
	gen FE_Vdeaths_`num' = FEdeaths_`num' - FE_NVdeaths_`num'
	}
	
forval num = 1/9 {
	gen FE_VdeathsPM_`num' = (FE_Vdeaths_`num'/population) * 1000000
	}
	
line FE_NVdeathsPM_1 year, lc("166 206 227") lw(medthick) ///
	|| line FE_NVdeathsPM_2 year, lc("31 120 180") lw(medthick)  ///
	|| line FE_NVdeathsPM_3 year, lc("178 223 138") lw(medthick)  ///
	|| line FE_NVdeathsPM_4 year, lc("51 160 44") lw(medthick)  ///
	|| line FE_NVdeathsPM_5 year, lc("251 154 153") lw(medthick)  ///
	|| line FE_NVdeathsPM_6 year, lc("227 26 28") lw(medthick)  ///
	|| line FE_NVdeathsPM_7 year, lc("253 191 111") lw(medthick)  ///
	|| line FE_NVdeathsPM_8 year, lc("255 127 0") lw(medthick)  ///
	|| line FE_NVdeathsPM_9 year, lc("202 178 214") lw(medthick)  ///
	title("Police-involved {bf:non-vehicular} deaths, 2000-2020", size(small)) ///
	subtitle("per 1M residents", size(vsmall)) ///
	legend(pos(6) size(vsmall) rows(3) label(1 "East North Central") label(2 "East South Central") label(3 "Mid Atlantic") ///
		label(4 "Mountain") label(5 "New England") label(6 "Pacific") ///
		label(7 "South Atlantic") label(8 "West North Central") label(9 "West South Central")) ///
	plotr(fc(gs16) lc(gs18)) ///
	yla(0(1)10, labs(vsmall)) yscale(range(0(1)10)) ytitle("") ///
	xla(2000(1)2020, labs(vsmall) angle(45) nogrid) xscale(range(2000(1)2020)) xtitle("") ///
	name(FE_nvh, replace)	
	
line FE_VdeathsPM_1 year, lc("166 206 227") lw(medthick) ///
	|| line FE_VdeathsPM_2 year, lc("31 120 180") lw(medthick)  ///
	|| line FE_VdeathsPM_3 year, lc("178 223 138") lw(medthick)  ///
	|| line FE_VdeathsPM_4 year, lc("51 160 44") lw(medthick)  ///
	|| line FE_VdeathsPM_5 year, lc("251 154 153") lw(medthick)  ///
	|| line FE_VdeathsPM_6 year, lc("227 26 28") lw(medthick)  ///
	|| line FE_VdeathsPM_7 year, lc("253 191 111") lw(medthick)  ///
	|| line FE_VdeathsPM_8 year, lc("255 127 0") lw(medthick)  ///
	|| line FE_VdeathsPM_9 year, lc("202 178 214") lw(medthick)  ///
	title("Police-involved {bf:vehicular} deaths, 2000-2020", size(small)) ///
	subtitle("per 1M residents", size(vsmall)) ///
	legend(pos(6) size(vsmall) rows(3) label(1 "East North Central") label(2 "East South Central") label(3 "Mid Atlantic") ///
		label(4 "Mountain") label(5 "New England") label(6 "Pacific") ///
		label(7 "South Atlantic") label(8 "West North Central") label(9 "West South Central")) ///
	plotr(fc(gs16) lc(gs18)) ///
	yla(0(.5)4, labs(vsmall)) yscale(range(0(.5)4)) ytitle("") ///
	xla(2000(1)2020, labs(vsmall) angle(45) nogrid) xscale(range(2000(1)2020)) xtitle("") ///
	name(FE_vh, replace)
