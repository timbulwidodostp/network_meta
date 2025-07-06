{smcl}
{title:Title}

{p 4 4 2}
Visualizing assumptions and results in network meta-analysis: the {cmd:network graphs} package

{title:Description}

{p 4 4 1}
The {cmd:network graphs} package provides a suite of commands producing graphical tools for network meta-analysis.

{title:List of commands}

{synoptset 20 tabbed}{...}
{synopt:{helpb networkplot}}Draw the plot of a network in terms of nodes and edges{p_end}

{synopt:{helpb netweight}}Estimate the contribution of direct comparisons in network estimates{p_end}

{synopt:{helpb ifplot}}Assess the presence of statistical inconsistency{p_end}

{synopt:{helpb netfunnel}}Draw the comparison-adjusted funnel plot{p_end}

{synopt:{helpb intervalplot}}Draw a forest plot with the network estimates and their confidence and predictive intervals{p_end}

{synopt:{helpb netleague}}Produce a 'league table' with the network estimates for all pairwise relative effects{p_end}

{synopt:{helpb sucra}}Estimate the relative ranking of treatmetns using probabilities{p_end}

{synopt:{helpb mdsrank}}Estimate the relative ranking of treatmetns using multidimensional scaling{p_end}

{synopt:{helpb clusterank}}Present the relative ranking of treatmetns for two outcomes{p_end}

{title:Updates}

{p 4 4 2}
You can get the latest version of this package from {stata "net from http://clinicalepidemio.fr/Stata"}. To run the commands the latest versions of {helpb metan}, {helpb metareg} and {helpb mvmeta} or {helpb network} are required.

{title:Examples}

{pstd}- Load and prepare appropriately the data for efficacy of the antidiabetics network {help network_graphs##Phung2010:(Phung, 2010)}:{p_end}

{phang}{cmd:. use "http://clinicalepidemio.fr/Stata/antidiabetics_efficacy_wide.dta", clear}{p_end}
{phang}  {stata "use http://clinicalepidemio.fr/Stata/antidiabetics_efficacy_wide.dta, clear":(click to run)}{p_end}

{phang}{cmd:. network import, tr(t1 t2) eff(ES) study(id) stderr(seES)}{p_end}
{phang}  {stata "network import, tr(t1 t2) eff(ES) study(id) stderr(seES)":(click to run)}{p_end}

{pstd}- Produce the plot of the network, giving information on the network structure, the number of studies evaluating each intervention,
the precision of the direct estimate for each pairwise comparison and the average bias level for every comparison with respect to blinding:{p_end}

{phang}{cmd:. gen invvarES=1/(seES^2)}{p_end}
{phang}  {stata "gen invvarES=1/(seES^2)":(click to run)}{p_end}
{phang}{cmd:. networkplot t1 t2, edgew(invvarES) edgecol(by blinding mean) edgesc(1.2) asp(0.8) lab(Placebo Sulfonylurea "DPP-4 inhibitor" Thiazolidinedione "GLP-1 analog" AGI Glinine)}{p_end}
{phang}  {stata `"networkplot t1 t2, edgew(invvarES) edgecol(by blinding mean) edgesc(1.2) asp(0.8) lab(Placebo Sulfonylurea "DPP-4 inhibitor" Thiazolidinedione "GLP-1 analog" AGI Glinine)"':(click to run)}{p_end}

{pstd}- Load and prepare appropriately the data of the antiplatelet regimens network {help network_graphs##Thijs2008:(Thijs, 2008)}:{p_end}

{phang}{cmd:. use "http://clinicalepidemio.fr/Stata/antiplatelet.dta", clear}{p_end}
{phang}  {stata "use http://clinicalepidemio.fr/Stata/antiplatelet.dta, clear":(click to run)}{p_end}

{phang}{cmd:. network import, tr(t1 t2) eff(ES) study(id) stderr(seES)}{p_end}
{phang}  {stata "network import, tr(t1 t2) eff(ES) study(id) stderr(seES)":(click to run)}{p_end}

{pstd}- Produce the contribution plot of the network:{p_end}

{phang}{cmd:. netweight ES seES t1 t2,asp(0.9) notab}{p_end}
{phang}  {stata "netweight ES seES t1 t2,asp(0.9) notab":(click to run)}{p_end}

{pstd}- Considering that study risk of bias might be associated with their year of publication,
produce a bar-graph showing how much information comes from high, unclear and low risk of bias studies for each network estimate{p_end}

{phang}{cmd:. netweight ES seES t1 t2,bar(by rob mean) notab}{p_end}
{phang}  {stata "netweight ES seES t1 t2,bar(by rob mean) notab":(click to run)}{p_end}

{pstd}- Assess the presence of inconsistency in every closed loop of the network:{p_end}

{phang}{cmd:. ifplot ES seES t1 t2 id, eform plotopt(texts(180)) xlab(1,1.3,1.8) notab}{p_end}
{phang}  {stata "ifplot ES seES t1 t2 id, eform plotopt(texts(180)) xlab(1,1.3,1.8) notab":(click to run)}{p_end}

{pstd}- Load and prepare appropriately the data for efficacy of the antidiabetics network:{p_end}

{phang}{cmd:. use "http://clinicalepidemio.fr/Stata/antidiabetics_efficacy_wide.dta", clear}{p_end}
{phang}  {stata "use http://clinicalepidemio.fr/Stata/antidiabetics_efficacy_wide.dta, clear":(click to run)}{p_end}

{phang}{cmd:. network import, tr(t1 t2) eff(ES) study(id) stderr(seES)}{p_end}
{phang}  {stata "network import, tr(t1 t2) eff(ES) study(id) stderr(seES)":(click to run)}{p_end}

{pstd}- Assess whether small and large trials tend to give different efficacy results focusing on the comparisons of all active treatments against placebo:{p_end}

{phang}{cmd:. netfunnel ES seES t1 t2 if t2=="1", ylab(0 0.1 0.2 0.3)}{p_end}
{phang}  {stata `"netfunnel ES seES t1 t2 if t2=="1",  ylab(0 0.1 0.2 0.3)"':(click to run)}{p_end}

{pstd}- Load the data of the antihypertensives network {help network_graphs##Elliott2007:(Elliott, 2007)}:{p_end}

{phang}{cmd:. use "http://clinicalepidemio.fr/Stata/antihypertensives.dta", clear}{p_end}
{phang}  {stata "http://clinicalepidemio.fr/Stata/antihypertensives.dta, clear":(click to run)}{p_end}

{pstd}- Perform network meta-analysis to obtain the network estimates of the relative effects and then estimate and plot the predictive intervals:{p_end}

{phang}{cmd:. network setup r n, stud(id) trt(t) num ref(1)}{p_end}
{phang}  {stata "network setup r n, stud(id) trt(t) num ref(1)":(click to run)}{p_end}
{phang}{cmd:. network meta c}{p_end}
{phang}  {stata "network meta c":(click to run)}{p_end}
{phang}{cmd:. intervalplot, eform pred null(1) lab(Placebo BB Diuretics CCB ACE ARB) marg(10 40 5 5) notab}{p_end}
{phang}  {stata "intervalplot, eform pred null(1) lab(Placebo BB Diuretics CCB ACE ARB) marg(10 40 5 5) notab":(click to run)}{p_end}

{pstd}- Then, produce the league table of the network ordering the treatments according to their relative ranking based on the SUCRA percentages:{p_end}

{phang}{cmd:. netleague, lab(Placebo BB Diuretics CCB ACE ARB) sort(ARB ACE Placebo CCB BB Diuretics) eform}{p_end}
{phang}  {stata "netleague, lab(Placebo BB Diuretics CCB ACE ARB) sort(ARB ACE Placebo CCB BB Diuretics) eform":(click to run)}{p_end}

{pstd}- Run again the network meta-analysis model and obtain the ranking probabilities for all competing treatments in the network. Then, produce the rankograms:{p_end}

{phang}{cmd:. network rank min,zero all reps(10000) gen(prob)}{p_end}
{phang}  {stata "network rank min,zero all reps(10000) gen(prob)":(click to run)}{p_end}
{phang}{cmd:. sucra prob*, lab(Placebo BB Diuretics CCB ACE ARB) rankog}{p_end}
{phang}  {stata "sucra prob*, lab(Placebo BB Diuretics CCB ACE ARB) rankog":(click to run)}{p_end}

{pstd}- Run again the network meta-analysis model and obtain the predictive ranking probabilities.
Then, compare the cumulative ranking plots based on the estimated and the predictive ranking probabilities:{p_end}

{phang}{cmd:. network rank min,zero all reps(10000) gen(pred_prob) predict}{p_end}
{phang}  {stata "network rank min,zero all reps(10000) gen(pred_prob) predict":(click to run)}{p_end}
{phang}{cmd:. sucra prob*, lab(Placebo BB Diuretics CCB ACE ARB) comp(pred_prob*) n("Estimated probabilities" "Predictive probabilities")}{p_end}
{phang}  {stata `"sucra prob*, lab(Placebo BB Diuretics CCB ACE ARB) comp(pred_prob*) n("Estimated probabilities" "Predictive probabilities")"':(click to run)}{p_end}

{pstd}- Obtain the estimated relative effects in the dataset and estimate the relative ranking of treatments using the multidimensional scaling method:{p_end}

{phang}{cmd:. mdsrank,best(max)}{p_end}
{phang}  {stata "mdsrank,best(max)":(click to run)}{p_end}

{pstd}- Obtain the SUCRA percentages for efficacy for the antidiabetics network:{p_end}

{phang}{cmd:. use "http://clinicalepidemio.fr/Stata/antidiabetics_efficacy_long.dta", clear}{p_end}
{phang}  {stata "use http://clinicalepidemio.fr/Stata/antidiabetics_efficacy_long.dta, clear":(click to run)}{p_end}
{phang}{cmd:. network setup y sd n, stud(id) trt(t) ref(1) num}{p_end}
{phang}  {stata "network setup y sd n, stud(id) trt(t) ref(1) num":(click to run)}{p_end}
{phang}{cmd:. network meta c}{p_end}
{phang}  {stata "network meta c":(click to run)}{p_end}
{phang}{cmd:. network rank min,zero all reps(10000) gen(eff_prob)}{p_end}
{phang}  {stata "network rank min,zero all reps(10000) gen(eff_prob)":(click to run)}{p_end} 
{phang}{cmd:. sucra eff_prob*, lab(Placebo Sulfonylurea "DPP-4 inhibitor" Thiazolidinedione "GLP-1 analog" AGI Glinine) noplot}{p_end}
{phang}  {stata `"sucra eff_prob*, lab(Placebo Sulfonylurea "DPP-4 inhibitor" Thiazolidinedione "GLP-1 analog" AGI Glinine) noplot"':(click to run)}{p_end}	

{pstd}- Obtain the SUCRA percentages for tolerability for the antidiabetics network:{p_end}

{phang}{cmd:. use "http://clinicalepidemio.fr/Stata/antidiabetics_tolerability.dta", clear}{p_end}
{phang}  {stata "http://clinicalepidemio.fr/Stata/antidiabetics_tolerability.dta, clear":(click to run)}{p_end}
{phang}{cmd:. network setup y sd n, stud(id) trt(t) ref(1) num}{p_end}
{phang}  {stata "network setup y sd n, stud(id) trt(t) ref(1) num":(click to run)}{p_end}
{phang}{cmd:. network meta c}{p_end}
{phang}  {stata "network meta c":(click to run)}{p_end}
{phang}{cmd:. network rank min,zero all reps(10000) gen(tol_prob)}{p_end}
{phang}  {stata "network rank min,zero all reps(10000) gen(tol_prob)":(click to run)}{p_end} 	
{phang}{cmd:. sucra tol_prob*, lab(Placebo Sulfonylurea "DPP-4 inhibitor" Thiazolidinedione "GLP-1 analog" AGI Glinine) noplot}{p_end}
{phang}  {stata `"sucra tol_prob*, lab(Placebo Sulfonylurea "DPP-4 inhibitor" Thiazolidinedione "GLP-1 analog" AGI Glinine) noplot"':(click to run)}{p_end}

{pstd}- Load the dataset that contains the SUCRA percentages for efficacy and tolerability for the antidiabetics network:{p_end}

{phang}{cmd:. use "http://clinicalepidemio.fr/Stata/antidiabeticsSUCRAS.dta", clear}{p_end}
{phang}  {stata "use http://clinicalepidemio.fr/Stata/antidiabeticsSUCRAS.dta, clear":(click to run)}{p_end}

{pstd}- Present jointly the relative ranking of treatments for efficacy and acceptability:{p_end}

{phang}{cmd:. clusterank outcome1 outcome2 t}{p_end}
{phang}  {stata "clusterank outcome1 outcome2 t":(click to run)}{p_end}

{phang}** Note: Additional examples on the use of the commands can be found {browse "www.plosone.org/article/fetchSingleRepresentation.action?uri=info:doi/10.1371/journal.pone.0076654.s002":here}.  

{title:Limitations}

{p 4 4 2}
For large networks (e.g. icluding more than 10 treatments) the {cmd:netweight} command sometimes cannot produce the contribution plot and only gives the output results. 

{title:Authors}

{p 4 4 2}
Anna Chaimani, University of Ioannina School of Medicine, email: {browse "mailto:achaiman@cc.uoi.gr":achaiman@cc.uoi.gr}

{phang}
Georgia Salanti, University of Ioannina School of Medicine


{title:Acknowledgements}

{p 4 4 2}
Drs Julian Higgins, Dimitris Mavridis, Ian White, Panagiota Spyridonos and Deborah Caldwell provided very helpful comments on earlier versions of the commands.

{title:References}

{phang}{marker Bucher1997}Bucher HC, Guyatt GH, Griffith LE, Walter SD. The results of direct and indirect treatment comparisons in meta-analysis of randomized controlled trials. J Clin Epidemiol 1997, 50(6):683-91.
({browse "http://www.sciencedirect.com/science/article/pii/S0895435697000498":link to paper}){p_end}

{phang}{marker Caldwell2005}Caldwell DM, Ades AE, Higgins JPT. Simultaneous comparison of multiple treatments: combining direct and indirect evidence. BMJ 2005, 331(7521):897-900.
({browse "http://www.bmj.com/content/331/7521/897.short":link to paper}){p_end}

{phang}{marker Chaimani2012}Chaimani A, Salanti G. Using network meta-analysis to evaluate the existence of small-study effects in a network of interventions. Res Synth Meth 2012;3(2):161-176.
({browse "http://onlinelibrary.wiley.com/doi/10.1002/jrsm.57/abstract":link to paper}){p_end}

{phang}{marker Chaimani2013}Chaimani A, Higgins JPT, Mavridis D, Spyridonos P, Salanti G. Graphical tools for network meta-analysis in STATA. Plos One 8(10): e76654.
({browse "http://www.plosone.org/article/info:doi/10.1371/journal.pone.0076654":link to paper}){p_end}

{phang}{marker Cooper2009}Cooper H, Hedges LV, Valentine JC. The Handbook of Research Synthesis and Meta-Analysis. Russell Sage Foundation. 2009
({browse "https://www.russellsage.org/publications/handbook-research-synthesis-and-meta-analysis-second-edition":link to paper}){p_end}

{phang}{marker Elliott2007}Elliott WJ, Meyer PM. Incident diabetes in clinical trials of antihypertensive drugs: a network meta-analysis. Lancet 2007, 369:201–207.
({browse "http://www.ncbi.nlm.nih.gov/pubmed/17240286":link to paper}){p_end}

{phang}{marker Handl2005}Handl J, Knowles J, Kell DB. Computational cluster validation in post-genomic data analysis. Bioinformatics 2005, 21(15):3201-3212.
({browse "http://bioinformatics.oxfordjournals.org/content/21/15/3201.long":link to paper}){p_end}

{phang}{marker Higgins2009}Higgins JPT, Thompson SG, Spiegelhalter DJ. A re-evaluation of random-effects meta-analysis. J R Stat Soc Ser A 2009, 172: 137-159.
({browse "http://onlinelibrary.wiley.com/doi/10.1111/j.1467-985X.2008.00552.x/abstract":link to paper}){p_end}

{phang}{marker Jansen2013}Jansen JP, Naci H. Is network meta-analysis as valid as standard pairwise meta-analysis? It all depends on the distribution of effect modifiers. BMC Med 2013, 11:159.
({browse "http://www.biomedcentral.com/1741-7015/11/159":link to paper}){p_end}

{phang}{marker Jung2003}Jung Y, Park H, Du DZ, Drake BL. A decision criterion for the optimal number of clusters in hierarchical clustering. J Glob Optim 2003, 25(1):91-111.
({browse "http://link.springer.com/article/10.1023%2FA%3A1021394316112":link to paper}){p_end}

{phang}{marker Krahn2013}Krahn U, Binder H, Konig J. A graphical tool for locating inconsistency in network meta-analyses. BMC Med Res Methodol 2013, 13:35.
({browse "http://www.biomedcentral.com/1471-2288/13/35/abstract":link to paper}){p_end}

{phang}{marker Lu2011}Lu G, Welton NJ, Higgins JPT, White IR, Ades AE. Linear inference for mixed treatment comparison meta-analysis: A two-stage approach. Res Synth Meth 2011, 2:43-60.
({browse "http://onlinelibrary.wiley.com/doi/10.1002/jrsm.34/abstract":link to paper}){p_end}

{phang}{marker Lunn2000}Lunn DJ, THomas A, Best N, Spiegelhalter DJ. WinBUGS - a Bayesian modelling framework: concepts, structure, and extensibility. Stat & Comput 2000, 10:325-337.
({browse "http://link.springer.com/article/10.1023%2FA%3A1008929526011":link to paper}){p_end}

{phang}{marker Phung2010}Phung OJ, Scholle JM, Talwar M, Coleman CI. Effect of noninsulin antidiabetic drugs added to metformin therapy on glycemic control, weight gain, and hypoglycemia in type 2 diabetes. JAMA 2010, 303:1410-1418.
({browse "http://www.ncbi.nlm.nih.gov/pubmed/20388897":link to paper}){p_end}

{phang}{marker Riley2011}Riley RD, Higgins JPT, Deeks JJ. Interpretation of random effects meta-analyses. BMJ 2011, 342: d549.
({browse "http://www.bmj.com/content/342/bmj.d549":link to paper}){p_end}

{phang}{marker Salati2008}Salanti G, Higgins JPT, Ades AE, Ioannidis JPA. Evaluation of networks of randomized trials. Stat Meth Med Res 2008, 17(3):279-301.
({browse "http://smm.sagepub.com/content/17/3/279.abstract":link to paper}){p_end}

{phang}{marker Salanti2011}Salanti G, Ades AE, Ioannidis JPA. Graphical methods and numerical summaries for presenting results from multiple-treatment meta-analysis: an overview and tutorial. J Clin Epidemiol 2011, 64(2):163-71.
({browse "http://www.sciencedirect.com/science/article/pii/S0895435610001691":link to paper}){p_end}

{phang}{marker Salanti2012}Salanti G. Indirect and mixed-treatment comparison, network, or multiple-treatments meta-analysis: many names, many benefits, many concerns for the next generation evidence synthesis tool. Res Synth Meth 2012, 3(2):80-97.
({browse "http://onlinelibrary.wiley.com/doi/10.1002/jrsm.1037/abstract":link to paper}){p_end}

{phang}{marker Salanti2014}Salanti G, Giovane CD, Chaimani A, Caldwell DM, Higgins JPT. Evaluating the quality of evidence from a network meta-analysis. Plos One 2014, 9(7):e99682.
({browse "http://www.plosone.org/article/info%3Adoi%2F10.1371%2Fjournal.pone.0099682#pone-0099682-g007":link to paper}){p_end}

{phang}{marker Thijs2008}Thijs V, Lemmens R, Fieuws S. Network meta-analysis: simultaneous meta-analysis of common antiplatelet regimens after transient ischaemic attack or stroke. Eur Heart J 2008, 29:1086–1092.
({browse "http://www.ncbi.nlm.nih.gov/pubmed/18349026":link to paper}){p_end}

{phang}{marker Veroniki2014}Veroniki AA, Mavridis D, Higgins JPT, Salanti G. Characteristics of a loop of evidence that affect detection and estimation of inconsistency: a simulation study. BMC Med Res Methodol 2014, 14(1):106.
({browse "http://www.biomedcentral.com/1471-2288/14/106":link to paper}){p_end}

{phang}{marker White2011}White IR. Multivariate random-effects meta-regression: Updates to mvmeta. Stata Journal (2012) 11: 255-270.
({browse "http://www.stata-journal.com/article.html?article=st0156_1":link to paper}){p_end}

{phang}{marker White2012}White IR, Barrett JK, Jackson D, Higgins JPT. Consistency and inconsistency in network meta-analysis: model estimation using multivariate meta-regression. Res Synth Meth 2012, 3:111–125.
({browse "http://onlinelibrary.wiley.com/doi/10.1002/jrsm.1045/abstract":link to paper}){p_end}

{phang}{marker White2013}White IR, 2013. A suite of Stata programs for network meta-analysis. Presented at UK Stata User's Group, London. Available from ({browse "http://repec.org/usug2013/white.uk13.pptx":link to presentation}){p_end}

{title:See also}

{helpb metan}, {helpb metareg}, {helpb mvmeta}, {helpb network}.

{phang} 
