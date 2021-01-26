*********************************************************************************************************
* Nix & Richards (In Press)
* The immediate and long-term effects of COVID-19 stay-at-home orders on domestic violence calls for service across six U.S. jurisdictions
* Police Practice & Research, vol/pages TBD
* Code last updated 1/19/2021
*********************************************************************************************************

* Set macros for easy navigation to folders containing each jurisdiction's data
* Replace "~" with local path
	global cincinnati "~\cincinnati"
	global phoenix "~\phoenix"
	global nola "~\nola"
	global seattle "~\seattle"
	global salt "~\salt"
	global montgomery "~\montgomery"
	
* set scheme for graphs
	set scheme plottig
	
*********************************************************************************************************
* CINCINNATI
* Residents of Ohio ordered to stay at home on March 23rd
* Import, clean, and merge CPD CFS data [from https://data.cincinnati-oh.gov/Safety/PDI-Police-Data-Initiative-Police-Calls-for-Servic/gexm-h6bt]
	import delimited "$cincinnati\PDI__Police_Data_Initiative__Police_Calls_for_Service__CAD_2018.csv", clear
	save "$cincinnati\Cincinnati_CFS_2018.dta", replace
	
	import delimited "$cincinnati\PDI__Police_Data_Initiative__Police_Calls_for_Service__CAD_2019.csv", clear
	save "$cincinnati\Cincinnati_CFS_2019.dta", replace
	
	import delimited "$cincinnati\PDI__Police_Data_Initiative__Police_Calls_for_Service__CAD_2020.csv", clear
	
	merge m:m event_number using "$cincinnati\Cincinnati_CFS_2019.dta"
	merge m:m event_number using "$cincinnati\Cincinnati_CFS_2018.dta", gen(_merge2)
	save "$cincinnati\Cincinnati_CFS_2018-20.dta", replace

* generate dummies for domestic calls, traffic stops, and everything else
	gen cinD = 1 if incident_type_id == "DOMVIO"
	replace cinD = 1 if incident_type_id == "U-DOMESTIC VIOL IN PROGRESS"
	replace cinD = 1 if incident_type_id == "FAMTRB"
	replace cinD = 1 if incident_type_id == "DOMINP-COMBINED"
	
	tab incident_type_id if regexm(incident_type_desc, "TRAFFIC") == 1 // N = 110,659
	tab incident_type_id if regexm(incident_type_desc, "DIRECTED PATROL") == 1 // N = 151,837
	gen cinT = 1 if incident_type_id == "TSTOP" | incident_type_id == "TSTOP_2" | incident_type_id == "TRAF" | ///
		incident_type_id == "DIRPAT" | incident_type_id == "DIRPAW" | incident_type_id == "DIRVCT" | ///
		incident_type_id == "ACCP-PD TRAP" | incident_type_id == "HAZARD" | incident_type_id == "POST" | ///
		incident_type_id == "TPURS"
		
	gen cinND = 1 if cinD != 1 & cinT != 1
	
* Prepare the Date variable
	gen date2 = date(create_time_incident, "MDYhm")
	clonevar date = date2
	format date %td
	
* collapse to days
	collapse (sum) cinD cinT cinND, by(date)
	
* save a master time-series dataset
	save "$cincinnati\cin_cfs_ts.dta", replace
	
		
*********************************************************************************************************	
* PHOENIX
* Arizona put under stay-at-home order on March 31
	
* Import, clean, and merge PPD CFS data [from https://www.phoenixopendata.com/dataset/calls-for-service]
	import delimited using "$phoenix\callsforsrvc2018.csv", clear
	save "$phoenix\ppd_cfs_2018.dta", replace
	
	import delimited using "$phoenix\callsforsrvc2019.csv", clear
	save "$phoenix\ppd_cfs_2019.dta", replace
	
	import delimited using "$phoenix\callsforsrvc2020.csv", clear
	
	merge m:m incident_num using "$phoenix\ppd_cfs_2019.dta"
	merge m:m incident_num using "$phoenix\ppd_cfs_2018.dta", gen(_merge2)
	
	save "$phoenix\ppd_cfs_data.dta", replace
	
	drop _merge* hundred* grid

* generate dummies for domestic calls, traffic stops, and everything else
	gen phxD = regexm(final_call_type, "DOMESTIC VIOLENCE") == 1
	
	gen phxT = regexm(final_call_type, "TRAFFIC") == 1
	replace phxT = 1 if final_call_type == "PR CONTACT" | final_call_type == "SUBJECT STOP"
	
	gen phxND = 1 if phxD !=1 & phxT != 1
	
* extract from the Date variable
	gen date = date(call_received, "MDY hms")
	format date %td
	
* collapse to days
	collapse (sum) phxD phxT phxND, by(date)

* merge with master time-series dataset
	merge 1:1 date using "$cincinnati\cin_cfs_ts.dta"
	save "$phoenix\phx_cfs_ts.dta", replace
	
		
*********************************************************************************************************	
* NEW ORLEANS
* Residents ordered to stay at home....
* Import, clean, and merge NOPD CFS data [from https://nopdnews.com/transparency/policing-data/]
	import delimited using "$nola\Calls_For_Service_2018.csv", clear varn(1)
	save "$nola\nopd_cfs_2018.dta", replace
	
	import delimited using "$nola\Calls_For_Service_2019.csv", clear varn(1)
	save "$nola\nopd_cfs_2019.dta", replace
	
	import delimited using "$nola\Call_For_Service_2020.csv", clear varn(1)
	
	merge m:m nopd_item using "$nola\nopd_cfs_2019.dta"
	merge m:m nopd_item using "$nola\nopd_cfs_2018.dta", gen(_merge2) force
	
* generate dummies for domestic calls, traffic stops, and everything else
	gen nolaD = regexm(typetext, "DOMESTIC") == 1
	
	gen nolaT = regexm(typetext, "TRAFFIC") == 1
	replace nolaT = 1 if typetext == "WALKING BEAT"
	replace nolaT = 1 if typetext == "DIRECTED PATROL"
	
	gen nolaND = 1 if nolaD !=1 & nolaT != 1
	
* extract from the Date variable
	gen date_str = substr(timecreate, 1, 16)
	gen date2 = word(date_str, 1)
	gen date = date(date2, "MDY")
	format date %td
	
* collapse to days
	collapse (sum) nolaD nolaT nolaND, by(date)

* merge with other cities
	merge 1:1 date using "$phoenix\phx_cfs_ts.dta", gen(_merge2)
	save "$nola\nola_cfs_ts.dta", replace
	
	
*********************************************************************************************************	
* SEATTLE
* Washington residents ordered to stay at home on March 23rd
* Import, clean, and merge SPD CFS data [from https://data.seattle.gov/Public-Safety/Call-Data/33kz-ixgy/data]
* Note I only pulled 2018-2020 
	import delimited using "$seattle\Call_Data_2018-2020.csv", clear varn(1)
	
* generate dummies for domestic calls, traffic stops, and everything else
	gen seaD = regexm(initialcalltype, "DV") == 1
	replace seaD = 0 if regexm(initialcalltype, "ORDER") == 1 | regexm(initialcalltype, "NO WELFARE CHK OR DV") == 1 | regexm(initialcalltype, "NON DV") == 1 |regexm(initialcalltype, "NOT DV") == 1
	
	gen seaT = regexm(initialcalltype, "TRAF") == 1
	replace seaT = 1 if regexm(initialcalltype, "DIRECTED PATROL") == 1
	replace seaT = 1 if regexm(initialcalltype, "OFFICER INITIATED") == 1
	replace seaT = 1 if calltype == "ONVIEW" | calltype == "PROACTIVE (OFFICER INITIATED)"
	
	gen seaND = 1 if seaD != 1 & seaT != 1
	
* extract from the Date variable
	gen date_str = substr(originaltimequeued, 1, 10)
	gen date2 = word(date_str, 1)
	gen date = date(date2, "MDY")
	format date %td
	
* collapse to days
	collapse (sum) seaD seaT seaND, by(date)

* merge with other cities
	merge 1:1 date using "$nola\nola_cfs_ts.dta", gen(_merge3)
	save "$seattle\sea_cfs_ts.dta", replace
	

*********************************************************************************************************	
* SALT LAKE CITY
* residents advised to stay at home on March 27th
* Import, clean, and merge SLCPD CFS data [from https://opendata.utah.gov/salt-lake-city]
* Note I only pulled 2018-2020 	
	import delimited using "$salt\20-7662A SLCPD CAD 2018-2020.csv", varn(1) clear
	
* generate dummies for domestic calls, traffic stops, and everything else
	gen saltD = regexm(case_type_translation, "DOMESTIC") == 1
	
	gen saltT = regexm(case_type, "TRAF") == 1
	replace saltT = 1 if case_type == "PATR" // patrol check
	replace saltT = 1 if regexm(case_type_translation, "TRAF") == 1
	replace saltT = 0 if regexm(case_type_translation, "TRAFFICKING") == 1
	
	gen saltND = 1 if saltD != 1 & saltT != 1

* extract from the Date Variable
	gen date = date(received_dt, "MDY hm")
	format date %td
	
* collapse to days
	collapse (sum) saltD saltT saltND, by(date)
	
* merge with other cities
	merge 1:1 date using "$seattle\sea_cfs_ts.dta", gen(_merge4)
	save "$salt\salt_cfs_ts.dta", replace
	
*********************************************************************************************************	
* MONTGOMERY COUNTY, MD
* residents ordered to stay at home on March 30th
* Import, clean, and merge Montgomery CFS data [from https://data.montgomerycountymd.gov/Public-Safety/Police-Dispatched-Incidents/98cc-bc7d/data]
	import delimited using "$montgomery\Police_Dispatched_Incidents.csv", varn(1) clear
	
* generate dummies for domestic calls, traffic stops, and everything else
	gen montD = regexm(initialtype, "DOMESTIC") == 1
	
	gen montT = regexm(initialtype, "TRAFFIC") == 1
	replace montT = 0 if regexm(initialtype, "TRAFFICK") == 1
	
	gen montND = 1 if montD != 1 & montT != 1
	
* extract from the Date Variable
	gen date = date(starttime, "MDY hm")
	format date %td

* collapse to days
	collapse (sum) montD montT montND, by(date)
	
* merge with other cities
	merge 1:1 date using "$salt\salt_cfs_ts.dta", gen(_merge5)
	save "$montgomery\mont_cfs_ts.dta", replace

* generate a time-series variable, "week_num", reflecting the number of 7-day periods since January 1, 2018
	gen day = doy(date)
	gen week = week(date)
	gen month = month(date)
	gen year = year(date)
	gen int week_num = floor((date - td(1jan2018))/7) + 1
	sort date

* Week #157 starts on December 28, 2020 and only has 4 days. Drop these 4 days so we have 156 weeks of equal length. 
	display date("12-28-2020", "MDY")
	drop if date >= 22277
	
* collapse down to week_num for time series models
	collapse (sum) *D *T, by(week_num)
	
* before separate ITSA models, plot the 6 cities together

	line nolaD week_num, lc("27 158 119") lw(medium) ///
	|| line cinD week_num, lc("217 95 2") lw(medium) ///
	|| line seaD week_num, lc("117 112 179") lw(medium) ///
	|| line saltD week_num, lc("231 41 138") lw(medium) ///
	|| line montD week_num, lc("102 166 30") lw(medium) ///
	|| line phxD week_num, lc("230 171 2") lw(medium) ///
	leg(pos(6) size(small) rows(2) label(1 "New Orleans") label(2 "Cincinnati") label(3 "Seattle") label(4 "Salt Lake City") label(5 "Montgomery Co.") label(6 "Phoenix")) ///
	title("Domestics", size(small)) ///
	yla(0(50)600, labs(small)) yscale(range(0(50)600)) ytitle("Total Calls", size(small)) ///
	xla(1(5)156, labs(small) angle(90) nogrid) xmtick(1(1)156) xscale(range(1(2)156)) xtitle("Week Number", size(small) margin(top)) ///
	xline(116, lc(gs0)) xline(118, lc(gs0)) ///
	name(domestic_agg, replace)
	
	line nolaT week_num, lc("27 158 119") lw(medium) ///
	|| line cinT week_num, lc("217 95 2") lw(medium) ///
	|| line seaT week_num, lc("117 112 179") lw(medium) ///
	|| line saltT week_num, lc("231 41 138") lw(medium) ///
	|| line montT week_num, lc("102 166 30") lw(medium) ///
	|| line phxT week_num, lc("230 171 2") lw(medium) ///
	leg(pos(6) size(vsmall) rows(1) label(1 "New Orleans") label(2 "Cincinnati") label(3 "Seattle") label(4 "Salt Lake City") label(5 "Montgomery Co.") label(6 "Phoenix")) ///
	title("Traffic/Officer-Initiated Stops", size(small)) ///
	yla(0(300)4200, labs(vsmall)) yscale(range(0(300)4200)) ytitle("Total Stops", size(small)) ///
	xla(1(5)156, labs(vsmall) angle(90) nogrid) xmtick(1(1)156) xscale(range(1(2)156)) xtitle("Week Number", size(vsmall) margin(top)) ///
	xline(116, lc(gs0)) xline(118, lc(gs0)) ///
	name(traffic_agg, replace)
	
	line nolaND week_num, lc("27 158 119") lw(medium) ///
	|| line cinND week_num, lc("217 95 2") lw(medium) ///
	|| line seaND week_num, lc("117 112 179") lw(medium) ///
	|| line saltND week_num, lc("231 41 138") lw(medium) ///
	|| line montND week_num, lc("102 166 30") lw(medium) ///
	|| line phxND week_num, lc("230 171 2") lw(medium) ///
	leg(pos(6) size(small) rows(2) label(1 "New Orleans") label(2 "Cincinnati") label(3 "Seattle") label(4 "Salt Lake City") label(5 "Montgomery Co.") label(6 "Phoenix")) ///
	title("Other Calls for Service", size(small)) ///
	yla(1500(1000)13500, labs(small)) yscale(range(1500(1000)13500)) ytitle("Total Calls", size(small)) ///
	xla(1(5)156, labs(small) angle(90) nogrid) xmtick(1(1)156) xscale(range(1(2)156)) xtitle("Week Number", size(small) margin(top)) ///
	xline(116, lc(gs0)) xline(118, lc(gs0)) ///
	name(other_agg, replace)
	
* combine domestic v. non-domestic for FIGURE 1
	graph combine domestic_agg other_agg, rows(1)  ///
		note("*NOTE: Vertical lines indicate start of stay-at-home orders, which occurred as early as Week 116 or as late as Week 118 in our sample.", size(vsmall) pos(5))

		
* ITSA models: domestic CFS
tsset week_num
		
	* new orleans
		// Week #116
		itsa nolaD, cformat(%4.3f) sformat(%4.3f) pformat(%4.3f) replace single trperiod(116) posttrend fig(title("New Orleans (3/22/20)", size(small) margin(tiny)) ///
		subtitle("") ///
		msize(vsmall) mc("27 158 119") ///
		legend(off) ///
		xla(1(5)156, labs(vsmall) angle(90) nogrid) xmtick(1(1)156) xscale(range(1(2)156)) xtitle("Week Number", size(small)) ///
		yla(200(50)450, labs(vsmall)) yscale(range(200(50)450)) ytitle("Domestic CFS", size(small)) ///
		note("") name(nola_itsa1, replace) plotr(margin(tiny)) nodraw)
	
	* cincinnati
		// Week #117
		itsa cinD, cformat(%4.3f) sformat(%4.3f) pformat(%4.3f) replace single trperiod(117) posttrend fig(title("Cincinnati (3/23/20)", size(small) margin(tiny)) ///
		subtitle("") ///
		msize(vsmall) mc("217 95 2") ///
		legend(off) ///
		xla(1(5)156, labs(vsmall) angle(90) nogrid) xmtick(1(1)156) xscale(range(1(2)156)) xtitle("Week Number", size(small)) ///
		yla(250(25)450, labs(vsmall)) yscale(range(250(25)450)) ytitle("") ///
		note("") name(cin_itsa1, replace) plotr(margin(tiny)) nodraw)
			
		/* * Reviewer Comment: Look more closely at Cincinnati
				scatter cinD week_num, xline(113) xline(117) connect(l) ///
				title("DV calls for service in Cincinnati, 2018-2020", size(small)) ///
				xla(1(5)156, labs(vsmall) angle(90) nogrid) xmtick(1(1)156) xscale(range(1(2)156)) xtitle("Week Number", size(small)) ///
				yla(250(25)450, labs(vsmall)) yscale(range(250(25)450)) ytitle("DV CFS", size(small)) 
		*/

	* seattle
		// Week #117
		itsa seaD, cformat(%4.3f) sformat(%4.3f) pformat(%4.3f) replace single trperiod(117) posttrend fig(title("Seattle (3/23/20)", size(small) margin(tiny)) ///
		subtitle("") ///
		msize(vsmall) mc("117 112 179") ///
		legend(off) ///
		xla(1(5)156, labs(vsmall) angle(90) nogrid) xmtick(1(1)156) xscale(range(1(2)156)) xtitle("Week Number", size(small)) ///
		yla(100(25)250, labs(vsmall)) yscale(range(100(25)250)) ytitle("") ///
		note("") name(sea_itsa1, replace) plotr(margin(tiny)) nodraw)

	* salt lake city
		// Week #117
		itsa saltD, cformat(%4.3f) sformat(%4.3f) pformat(%4.3f) replace single trperiod(117) posttrend fig(title("Salt Lake City (3/27/20)", size(small) margin(tiny)) ///
		subtitle("") ///
		msize(vsmall) mc("231 41 138") ///
		legend(off) ///
		xla(1(5)156, labs(vsmall) angle(90) nogrid) xmtick(1(1)156) xscale(range(1(2)156)) xtitle("Week Number", size(small)) ///
		yla(50(25)175, labs(vsmall)) yscale(range(50(25)175)) ytitle("Domestic CFS", size(small)) ///
		note("") name(salt_itsa1, replace) plotr(margin(tiny)) nodraw)
		
	* montgomery county
		// Week #118
		itsa montD, cformat(%4.3f) sformat(%4.3f) pformat(%4.3f) replace single trperiod(118) posttrend fig(title("Montgomery Co. (3/30/20)", size(small) margin(tiny)) ///
		subtitle("") ///
		msize(vsmall) mc("102 166 30") ///
		legend(off) ///
		xla(1(5)156, labs(vsmall) angle(90) nogrid) xmtick(1(1)156) xscale(range(1(2)156)) xtitle("Week Number", size(small)) ///
		yla(175(25)350, labs(vsmall)) yscale(range(175(25)350)) ytitle("") ///
		note("") name(mont_itsa1, replace) plotr(margin(tiny)) nodraw)
		
	* phoenix
		// Week #118
		itsa phxD, cformat(%4.3f) sformat(%4.3f) pformat(%4.3f) replace single trperiod(118) posttrend fig(title("Phoenix (3/31/20)", size(small) margin(tiny)) ///
		subtitle("") ///
		msize(vsmall) mc("230 171 2") ///
		legend(off) ///
		xla(1(5)156, labs(vsmall) angle(90) nogrid) xmtick(1(1)156) xscale(range(1(2)156)) xtitle("Week Number", size(small)) ///
		yla(300(50)600, labs(vsmall)) yscale(range(300(50)600)) ytitle("") ///
		note("") name(phx_itsa1, replace) plotr(margin(tiny)) nodraw)

	* combine them for FIGURE 2
		graph combine nola_itsa1 cin_itsa1 sea_itsa1 salt_itsa1 mont_itsa1 phx_itsa1, rows(2) ///
		note("* Regressions with Newey-West standard errors - lag(0)", size(vsmall) pos(5) span margin(0 0 0 0)) ///
		plotr(margin(tiny)) graphr(margin(tiny)) name(comb1, replace)
		