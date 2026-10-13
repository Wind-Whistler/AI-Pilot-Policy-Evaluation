eststo clear

//基准回归
xtset id year
//面板连续数值回归
xtreg Eff Treat_Post UR FSSR LPGDP PS TL AS LFL i.year,fe vce(cluster id)
eststo model5
xtreg Eff Treat_Post , vce(cluster id)
eststo model1
xtreg Eff Treat_Post UR FSSR LPGDP PS TL AS LFL ,fe vce(cluster id)
eststo model3
xtreg Eff Treat_Post UR FSSR LPGDP PS TL AS LFL i.year,vce(cluster id)
eststo model4
xtreg Eff Treat_Post UR FSSR LPGDP PS TL AS LFL ,vce(cluster id)
eststo model2
//随机效应Tobit
xttobit Eff Treat_Post UR FSSR LPGDP PS TL AS LFL i.year i.id, ll (0) nolog 
tobit  Eff Treat_Post UR FSSR LPGDP PS TL AS LFL i.year i.id, ll (0) vce(cluster id)
//eststo model2
//多维模型固定效应
reghdfe Eff Treat_Post UR FSSR LPGDP PS TL AS LFL , absorb(id year) vce(cluster id)
//eststo model3
//输出结果
esttab model4 model5  using results.doc, b(%6.3f) se(%6.3f) star(* 0.1 ** 0.05 *** 0.01) stats(N r2_f, labels("N" "Within R-sq") fmt(%9.0f %6.3f)) mtitles("Eff" "Eff"  ) title("Regression Results") replace

eststo clear

//平行趋势检验
//多期did平行趋势
gen pd=year-policy_year 
tab pd
forvalues i = 13(-1)1{
	gen pre_`i'=(pd==-`i'& T==1)
}
gen current =(pd==0&T==1)
forvalues j = 1(1)13{
	gen las_`j'=(pd==`j'& T==1)
}
replace pre_1=0

xtset id year
//Tobit 或者 Xtreg 选一个
//面板连续模型回归
xtreg Eff  pre_8 pre_7 pre_6 pre_5 pre_4 pre_3 pre_2 current las_1 las_2 las_3 las_4  UR FSSR LPGDP PS TL AS LFL i.year,fe vce(cluster id)


est sto reg1

//平行趋势画图
coefplot,baselevels omitted keep(pre* current las*) vertical recast(connect) color(black) order( pre_8 pre_7 pre_6 pre_5 pre_4 pre_3 pre_2  current las_1 las_2 las_3 las_4 ) yline(0,lp(solid) lc(black)) ytitle("动态处理效应") xtitle("政策时点") xlabel( 1 "-8" 2 "-7" 3 "-6" 4 "-5" 5 "-4" 6 "-3" 7 "-2" 8 "0" 9 "1" 10 "2" 11 "3" 12 "4"  ) ciopts(recast(rcap) lc(black) lp(dash) lw(thin)) scale(1.0)

matrix list e(b)
matrix l_vec = 0 \ 1 \ 0 \ 0 \ 0
honestdid,l_vec(l_vec) pre(1/7) post(8/12) mvec(0(0.004)0.02) alpha(0.05)
local plotopts xtitle(平行趋势不成立的相对程度Mbar) ytitle(95%稳健置信区间) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) scheme(s1mono) 
honestdid, cached coefplot `plotopts'
matrix l_vec = 0 \ 0 \ 1 \ 0 \ 0
honestdid,l_vec(l_vec) pre(1/7) post(8/12) mvec(0(0.004)0.02) alpha(0.05)
local plotopts xtitle(平行趋势不成立的相对程度Mbar) ytitle(95%稳健置信区间) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) scheme(s1mono) 
honestdid, cached coefplot `plotopts'
matrix l_vec = 0 \ 0 \ 0 \ 1 \ 0
honestdid,l_vec(l_vec) pre(1/7) post(8/12) mvec(0(0.004)0.02) alpha(0.05)
local plotopts xtitle(平行趋势不成立的相对程度Mbar) ytitle(95%稳健置信区间) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) scheme(s1mono) 
honestdid, cached coefplot `plotopts'
matrix l_vec = 0 \ 0 \ 0 \ 0 \ 1
honestdid,l_vec(l_vec) pre(1/7) post(8/12) mvec(0(0.004)0.02) alpha(0.05)
local plotopts xtitle(平行趋势不成立的相对程度Mbar) ytitle(95%稳健置信区间) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) scheme(s1mono) 
honestdid, cached coefplot `plotopts'


eststo clear

//Uncertainty Estimates 
set seed 42
fect Eff, treat(Treat_Post) unit(id) time(year) cov(UR FSSR LPGDP PS TL AS LFL) method("fe") se preperiod(-8) offperiod(4) nboots(500) 
mat list e(ATT)

//Equivalence Test
set seed 42
fect Eff, treat(Treat_Post) unit(id) time(year) cov(UR FSSR LPGDP PS TL AS LFL) se method("fe") preperiod(-8) offperiod(0) equiTest nboots(500) title("FE")
fect Eff, treat(Treat_Post) unit(id) time(year) cov(UR FSSR LPGDP PS TL AS LFL) se method("ife") r(2) preperiod(-8) offperiod(0) equiTest nboots(500) title("IFE")
fect Eff, treat(Treat_Post) unit(id) time(year) cov(UR FSSR LPGDP PS TL AS LFL) se method("mc") lambda(0.004) preperiod(-8) offperiod(0) equiTest nboots(500) title("MC")

//稳健性部分
//DDML检验
//设置全局变量
global Y Eff 
global D Treat_Post
global X UR FSSR LPGDP PS TL AS LFL

//设置python路径
set python_exec "D:\ANA\python.exe"
set python_userpath "D:\Stata18\utilities"

//创建合理的折叠变量（基于地区的随机分割）
preserve
keep id
duplicates drop
set seed 42
gen random = runiform()
gen fid = (random > 0.5) + 1  
tempfile fold_assignment
save `fold_assignment'
restore
merge m:1 id using `fold_assignment', nogen
   
//初始化ddml模型
ddml init partial, foldvar(fid)

//添加监督机器学习以估计条件期望
ddml E[Y|X], gen(regy): reg $Y $X
ddml E[D|X], gen(regd): reg $D $X

ddml E[Y|X]: pystacked $Y $X, type(reg) method (lassocv)
ddml E[D|X]: pystacked $D $X, type(reg) method (lassocv)
//执行交叉拟合步骤
ddml crossfit
//输出结果
ddml estimate, vce(cluster id)
//DDML结果保存
matrix b = e(b)     
matrix V = e(V)   
local N = e(N)

// 创建临时名称存储结果（例如 "ddml_result"）
estimates clear

// 使用 ereturn post 而不是 estimates post
ereturn post b V, obs(`N')

// 给模型起个名字，方便输出
eststo ddml_model

esttab ddml_model using ddml_results.doc, title("DML Estimation Results") mtitles("DML Model") b(%6.3f) se(%6.3f) t(%6.2f) star(* 0.1 ** 0.05 *** 0.01) stats(N, labels("Observations") fmt(%9.0f)) replace 

eststo clear

//CSDID
gen first_treat = policy_year if T == 1
bysort id: egen gvar = min(first_treat)
replace gvar = 0 if gvar == . 
csdid Eff, x(UR FSSR LPGDP PS TL AS LFL) ivar( id) time( year) gvar(gvar)
estat simple
estat calendar
estat group
estat event  

//安慰剂检验
preserve
gen placebo_year = policy_year - 3 if T == 1 & policy_year - 3 >= 2011
gen placebo_Treat_Post = (year >= placebo_year & T == 1)
xtreg Eff placebo_Treat_Post UR FSSR LPGDP PS TL AS LFL i.year, fe vce(cluster id)
est store placebo_time
restore

//PlaceboTest
set seed 42
fect Eff, treat(Treat_Post) unit(id) time(year) cov(UR FSSR LPGDP PS TL AS LFL) se method("fe") placeboTest nboots(500) title("FE")
mat list e(placebo_ATT)
fect Eff, treat(Treat_Post) unit(id) time(year) cov(UR FSSR LPGDP PS TL AS LFL) se method("ife") r(2) placeboTest nboots(500) title("IFE")
mat list e(placebo_ATT)
fect Eff, treat(Treat_Post) unit(id) time(year) cov(UR FSSR LPGDP PS TL AS LFL) se method("mc") lambda(0.004) placeboTest nboots(500) title("MC")
mat list e(placebo_ATT)

//去除政策当期的回归
gen rel_time = year - policy_year if T == 1 & year - policy_year>=0
replace rel_time = -99 if T == 0
xtreg Eff Treat_Post UR FSSR LPGDP PS TL AS LFL i.year if rel_time != 0, fe vce(cluster id)

* 9.2 检验TWFE的负权重问题（如果使用传统DID）
twowayfeweights Eff id year Treat_Post, type(feTR)


//中介效应
//逐步回归
xtset id year

xttobit Eff Treat_Post UR FSSR LPGDP PS TL AS LFL i.year , ll (0)  nolog 
eststo model1
xttobit LFHSE Treat_Post UR FSSR LPGDP PS TL AS LFL i.year , ll (0)  nolog 
eststo model2
xttobit Eff Treat_Post LFHSE UR FSSR LPGDP PS TL AS LFL i.year , ll (0)  nolog 
eststo model3

xtreg Eff Treat_Post UR FSSR LPGDP PS TL AS LFL i.year,fe vce(cluster id)
eststo model1
xtreg LFHSE Treat_Post UR FSSR LPGDP PS TL AS LFL i.year,fe vce(cluster id)
eststo model2
xtreg Eff Treat_Post LFHSE UR FSSR LPGDP PS TL AS LFL i.year,fe vce(cluster id)
eststo model3
* 输出到 Word 文档
esttab model1 model2 model3 using "Mediation_Results.doc", title("中介效应检验") mtitles("Eff (1)" "LFHSE (2)" "Eff (3)") b(%6.3f) se(%6.3f) star(* 0.1 ** 0.05 *** 0.01) stats(N, labels("Observations") fmt(%9.0f)) keep(Treat_Post LFHSE UR FSSR LPGDP PS TL AS LFL) varlabels( Treat_Post "Treat × Post" LFHSE "地方财政住房保障支出" UR "城镇化率" FSSR "财政自给率" LPGDP "人均GDP (ln)" PS "人口规模" TL "税收水平" AS "年龄结构" LFL "劳动力水平" ) scalars("")  replace 

//Sobel检验
sgmediation Eff , mv( LFHSE ) iv( Treat_Post ) cv(UR FSSR LPGDP PS TL AS LFL)

//Bootstrap检验
tab id,gen(d_id)
tab year,gen(d_year)
bootstrap r(ind_eff) r(dir_eff), reps(500): sgmediation Eff , mv( LFHSE) iv( Treat_Post) cv(UR FSSR LPGDP PS TL AS LFL  d_id1-d_id29 d_year1-d_year12)
estat bootstrap, percentile bc
//bs1置信区间包含0，中介效应不成立
//若直接效应（bs_2）的置信区间不包括0就表明是【部分中介效应】：若直接效应（_bs_2）的置信区间包括e就表明是【完全中介效应】。（此处为x对y的影响）

eststo clear

//调节效应
center Treat_Post IUI
xttobit Eff Treat_Post c.c_Treat_Post#c.c_IUI IUI UR FSSR LPGDP PS TL AS LFL i.year,ll (0)  nolog 

center Treat_Post IUI
xtreg Eff Treat_Post c.c_Treat_Post#c.c_IUI IUI UR FSSR LPGDP PS TL AS LFL i.year,fe vce(cluster id)

eststo mod_interact

* 5. 输出到 Word
esttab mod_interact using "Moderation_Results.doc", title("调节效应分析结果") b(%6.3f) se(%6.3f) star(* 0.1 ** 0.05 *** 0.01) stats(N ll r2_p, labels("Observations" "Log Likelihood" "Pseudo R-squared") fmt(%9.0f %6.3f %6.3f)) varlabels( c.c_Treat_Post "Treat_Post (centered)" c.c_IUI "IUI (centered)" c.c_Treat_Post#c.c_IUI "Treat_Post × IUI (centered)" ) replace 

eststo clear

//工具变量
xtset id year
xtreg Eff Treat_Post UR FSSR LPGDP PS TL AS LFL i.year,fe vce(cluster id)

ivreghdfe Eff UR FSSR LPGDP PS TL AS LFL (Treat_Post=AI_Num),absorb(id year) vce(cluster id) first endog(Treat_Post)

//结果导出
reghdfe Treat_Post AI_Num UR FSSR LPGDP PS TL AS LFL,absorb(id year) vce(cluster id) 
outreg2 using result.doc,replace tstat bdec(4) tdec(4) addtext(Firm FE,Yes, Year FE, Yes) ctitle(First)
ivreghdfe Eff UR FSSR LPGDP PS TL AS LFL (Treat_Post=AI_Num),absorb(id year) vce(cluster id) first 
outreg2 using result.doc,append tstat bdec(4) tdec(4) addtext(Firm FE,Yes, Year FE, Yes) ctitle(Second)
 
eststo clear
 
//异质性分析
preserve
sum PCEE, detail
local mean_val = r(p50)

// 高 PCEE 组（大于等于平均值）
xtreg Eff Treat_Post UR FSSR LPGDP PS TL AS LFL i.year if PCEE >= `mean_val', fe vce(cluster id)
est store subsample_high

// 低 PCEE 组（小于平均值）
xtreg Eff Treat_Post UR FSSR LPGDP PS TL AS LFL i.year if PCEE < `mean_val', fe vce(cluster id)
est store subsample_low

restore

preserve
sum PCEE, detail
local mean_val = r(p50)

bys year: center Treat_Post UR FSSR LPGDP PS TL AS LFL Eff if PCEE <= `mean_val',prefix(low_year_)
bys id: center low_year_* if PCEE <= `mean_val', prefix(low_id_)

* 第二组：高教育支出组（去均值）
bys year: center Treat_Post UR FSSR LPGDP PS TL AS LFL Eff if PCEE > `mean_val', prefix(high_year_)
bys id: center high_year_* if PCEE > `mean_val', prefix(high_id_)

* 第二阶段回归（低教育支出组）
xtreg Eff Treat_Post UR FSSR LPGDP PS TL AS LFL i.year if PCEE <= `mean_val', fe vce(cluster id)
local dof1=e(df_r)
reg low_id_low_year_Eff low_id_low_year_Treat_Post low_id_low_year_UR low_id_low_year_FSSR low_id_low_year_LPGDP low_id_low_year_PS low_id_low_year_TL low_id_low_year_AS low_id_low_year_LFL if PCEE <= `mean_val', nocons dof(`dof1')
estimates store low

* 第二阶段回归（高教育支出组）
xtreg Eff Treat_Post UR FSSR LPGDP PS TL AS LFL i.year if PCEE > `mean_val', fe vce(cluster id)
local dof2=e(df_r)
reg high_id_high_year_Eff high_id_high_year_Treat_Post high_id_high_year_UR high_id_high_year_FSSR high_id_high_year_LPGDP high_id_high_year_PS high_id_high_year_TL high_id_high_year_AS high_id_high_year_LFL if PCEE > `mean_val', nocons dof(`dof2')
estimates store high

* 使用 suest
suest low high
test [low_mean]low_id_low_year_Treat_Post = [high_mean]high_id_high_year_Treat_Post

restore


* 使用 esttab 将结果导出到 Word 文件（.doc 或 .docx）
esttab subsample_high subsample_low using "AI_policy_subsample_results.doc",replace title("高、低人均教育支出样本回归结果对比") mtitles("高教育支出组" "低教育支出组") label se b(3) se(3) star(* 0.1 ** 0.05 *** 0.01) stats(N ll r2_p, fmt(0 2 3) labels("Observations" "Log Likelihood" "Pseudo R-squared")) alignment(D) page(on) keep(Treat_Post UR FSSR LPGDP PS TL AS LFL) 

//IV
preserve
sum PCEE, detail
local mean_val = r(p50)

xtreg Treat_Post AI_Num UR FSSR LPGDP PS TL AS LFL i.year if PCEE >= `mean_val', fe vce(cluster id)
predict double Treat_Post_hat_high, xb

xtreg Treat_Post AI_Num UR FSSR LPGDP PS TL AS LFL i.year if PCEE < `mean_val', fe vce(cluster id)
est store subsample_low
predict double Treat_Post_hat_low, xb

xtreg Eff Treat_Post_hat_high UR FSSR LPGDP PS TL AS LFL i.year if PCEE >= `mean_val', fe vce(cluster id)
xtreg Eff Treat_Post_hat_low UR FSSR LPGDP PS TL AS LFL i.year if PCEE < `mean_val', fe vce(cluster id)

restore

preserve
sum PCEE, detail
local mean_val = r(p50)

bys year: center Treat_Post AI_Num UR FSSR LPGDP PS TL AS LFL Eff if PCEE <= `mean_val',prefix(low_year_)
bys id: center low_year_* if PCEE <= `mean_val', prefix(low_id_)

* 第二组：高教育支出组（去均值）
bys year: center Treat_Post AI_Num UR FSSR LPGDP PS TL AS LFL Eff if PCEE > `mean_val', prefix(high_year_)
bys id: center high_year_* if PCEE > `mean_val', prefix(high_id_)

* 第一阶段回归（低教育支出组）
reg low_id_low_year_Treat_Post low_id_low_year_AI_Num low_id_low_year_UR low_id_low_year_FSSR low_id_low_year_LPGDP low_id_low_year_PS low_id_low_year_TL low_id_low_year_AS low_id_low_year_LFL if PCEE <= `mean_val'
predict double Treat_Post_hat_low, xb

* 第一阶段回归（高教育支出组）
reg high_id_high_year_Treat_Post high_id_high_year_AI_Num high_id_high_year_UR high_id_high_year_FSSR high_id_high_year_LPGDP high_id_high_year_PS high_id_high_year_TL high_id_high_year_AS high_id_high_year_LFL if PCEE> `mean_val'
predict double Treat_Post_hat_high, xb

* 第二阶段回归（低教育支出组）
reg low_id_low_year_Eff Treat_Post_hat_low low_id_low_year_UR low_id_low_year_FSSR low_id_low_year_LPGDP low_id_low_year_PS low_id_low_year_TL low_id_low_year_AS low_id_low_year_LFL if PCEE <= `mean_val'
estimates store low

* 第二阶段回归（高教育支出组）
reg high_id_high_year_Eff Treat_Post_hat_high high_id_high_year_UR high_id_high_year_FSSR high_id_high_year_LPGDP high_id_high_year_PS high_id_high_year_TL high_id_high_year_AS high_id_high_year_LFL if PCEE > `mean_val'
estimates store high

* 使用 suest
suest low high
test [low_mean]Treat_Post_hat_low = [high_mean]Treat_Post_hat_high

restore