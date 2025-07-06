{smcl}

{p}{helpb network_graphs: Return to main help page for the network graphs package}

{hline}
help for {hi:sucra} command
{hline}

{title:Title}

{p 4 4 2}
Ranking of treatments in networks of interventions using probabilities of assuming up to a specific rank


{title:Description}


{pstd}When performing a network meta-analysis it is common to estimate the ranking probabilities {it:p_tr} for each treatment {it:t} being at order {it:r}.
Then, the competing treatments can be classified using the cumulative probabilities {it:p.cum_tr} that treatment {it:t} is ranked among the first {it:r} places.
Two relative ranking measures that account for the uncertainty in treatment order are:{p_end}
{phang}1. the surface under the cumulative ranking curves (SUCRA) that expresses the percentage of effectiveness/safety each treatment has compared to an 'ideal' treatment ranked always first without uncertainty
{help network_graphs##Salanti2011:(Salanti, 2011)}{p_end}
{phang}2. the mean rank which is the mean of the distribution of the ranking probabilities{p_end}

{p 4 4 1}
The sucra command gives the SUCRA percentages and the mean ranks and produces rankograms (line plots of the probabilities vs. ranks) and cumulative ranking plots (line plots of the cumulative probabilities vs. ranks)
for all treatments in a network of interventions.  

{p 4 4 1}
An alternative equivalent to SUCRA ranking measure is the P-score and is also available in the sucra command {help network_graphs##Rucker2015:(Rucker, 2015)}. 

{title:Syntax}

{p 8 17 2}
{cmd:sucra}
[{it:varlist}]
{cmd:,}   
[{cmdab:mvmeta:results}
{cmdab:nomv:meta}
{cmdab:comp:are(}{it:varlist}{cmd:)}
{cmdab:s:tats(}{it:string}{cmd:)}
{cmdab:rp:robabilities(}{it:string}{cmd:)}
{cmdab:rev:erse}
{cmdab:rankog:rams}
{cmdab:n:ames(}{it:string}{cmd:)}
{cmdab:lab:els(}{it:string}{cmd:)}
{cmdab:lcol:ol(}{it:string}{cmd:)}
{cmdab:lpat:tern(}{it:string}{cmd:)}
{cmdab:notab:le}
{cmdab:nopl:ot}
{cmdab:tit:le(}{it:string}{cmd:)}
{cmdab:order:}
{cmdab:pscore:}
{cmdab:min|max:}
{cmdab:league:table}
{cmdab:sort:(}{it:string}{cmd:)}
{cmdab:exp:ort(}{it:string}{cmd:)}]

{p 4 4 2}

{pstd}The input in [{it:varlist}] is the ranking probabilities for all treatments and ranks from a network meta-analysis. This can be provided in three different ways:{p_end}

{phang}1. By running the sucra after performing network meta-analysis with the {cmd:mvmeta} (where the option {it:pbest(min|max,zero all reps() gen())} has been added; see {helpb mvmeta}) or {cmd:network rank min|max,zero all reps() gen()} (see {helpb network}).
These commands add in the data the t x r new variables each one corresponding to the probability of the rth rank for each treatment.
These new variables are typically named {it:probr_t} (where prob is the prefix we have specified in gen() of pbest(), r is the rank and t is the treatment)
and automatically appear at the end of the dataset. If {cmd:sucra} is run after mvmeta or network, the option {it:mvmetaresults}
may be specified ({bf:the default}) and all the variables containing the probability for a treatment being at a particular rank should be specified in [{it:varlist}].{p_end}

{phang}2. By providing the columns of the treatment-by-ranking probabilities matrix as variables in the dataset.
Then, all variables containing the ranking probabilities for each treatment should be specified in [{it:varlist}] and the option {it:nomvmeta} is required.{p_end}

{phang}3. By specifying the path of a .txt file where the ranking probabilities are stored (e.g. after running network meta-analysis in WinBUGS).
The path of the file should be specified in option {it:stats()} and the variable representing the ranking probabilities (e.g. "prob") in option {it:rprobabilities()}; the [{it:varlist}] should be omitted.
The command assumes that each node {it:prob[t,r]} in the .txt file ({it:t,r=1,...,T}, with {it:T} the total number of treatments)
represents the probability of treatment {it:t} being at order {it:r} and the opposite (i.e. {it:prob[r,t]}) when the option {it:reverse} has been specified.
The option {it:nomvmeta} is also required.

{phang}{ul:Important note:} The netweight command only reads datasets that have been prepared with {helpb network setup} or {helpb network import} in the augmented format{p_end}


{title:Options}

{phang}
{cmdab:comp:are(}{it:varlist}{cmd:)} specifies a second set of variables containing ranking probabilities.
These can be for example the ranking probabilities for the same treatments but for different outcome.
This option will add a second ranking plot to the existing ranking plot for each treatment. 

{phang}
{cmdab:rankog:rams} specifies that rankograms are drawn instead of cumulative ranking probability plots.

{phang}
{cmdab:n:ames(}{it:string}{cmd:)} specifies a label name for the first (specified in [{it:varlist}]) and second (specified in {it:compare(varlist)}) set of ranking probabilities. 
An example for relative ranking results from different outcomes would be names("Effectiveness" "Acceptability"). These label names are displayed in the output results and ranking plots.

{phang}
{cmdab:lab:els(}{it:string}{cmd:)} specifies names for competing treatments in the network, which are displayed in the raning plots and the output results.
The treatments should be given in numerical or alphabetical order separated by space.
When the option {it:nomvmeta} has not been specified, then the first treatment in {it:labels()} should be the treatment assumed the reference when running the {cmd:mvmeta} or {cmd:network} and the following treatments should be given in numerical or alphabetical order.
	
{phang}
{cmdab:lcol:ol(}{it:string}{cmd:)} specifies the color for the ranking plots corresponding to the first (specified in [{it:varlist}]) and second (specified in {it:compare(varlist)}) set of ranking probabilities (see {helpb line}).

{phang}
{cmdab:lpat:tern(}{it:string}{cmd:)} specifies the pattern for the ranking plots corresponding to the first (specified in [{it:varlist}]) and second (specified in {it:compare(varlist)}) set of ranking probabilities (see {helpb line}).

{phang}
{cmdab:notab:le} skips the display of the output results.

{phang}
{cmdab:nopl:ot} skips the display of the ranking plots.

{phang}
{cmdab:tit:le(}{it:string}{cmd:)} specifies the title for the ranking plots.

{phang}
{cmdab:order:} displays the treatments in tables and figures in the order of their relative ranking from best to worst.

{phang}
{cmdab:pscore:} calculates the P-score for each treatment instead of the SUCRA percentage. The ranking probabilities are not required as input in this case.

{phang}
{cmdab:min|max:} specifies whether smaller or larger values of the relative effects correspond to better treatments and is required for the calculation of the P-scores.

{phang}
{cmdab:league:table} specifies that a league table will be stored at the end of the dataset containing all pairwise probabilities that a treatment X is better than Y.

{phang}
{cmdab:sort:(}{it:string}{cmd:)} specifies the order for treatments from top to bottom in the league table with the pairwise probabilities. 
The names of treatments should be given as displayed in option {it:labels()}. By default, the treatments are ordered alphabetically/numerically from bottom to top with the reference treatment at the end.

{phang}
{cmdab:exp:ort(}{it:string}{cmd:)} specifies the path for an excel file where results are saved. 


{title:Examples}


{pstd}Input: Ranking probabilities derived from {helpb mvmeta} or {helpb network}{p_end}

{phang}{cmd:. network rank max, all zero gen(prob)}{p_end}
{phang}{cmd:. sucra prob*, rankogr lab(Placebo Aspirin Dipyridamole)}{p_end}

{phang}{cmd:. network rank max, all zero predict gen(predprob)}{p_end}
{phang}{cmd:. sucra prob*, comp(predprob*) name("Estimated Probabilities" "Predictive Probabiliites")}{p_end}


{pstd}Input: Ranking probabilities from the treatment-by-ranking probabilities matrix{p_end}

{phang}{cmd:. sucra Placebo Aspirin Dipyridamole, nomv}

{phang}{cmd:. sucra Effectiveness_t1-Effectiveness_t5, nomv comp(Acceptability_t1-Acceptability_t5) lab(A B C D E)}


{pstd}Input: Ranking probabilities derived from a .txt file{p_end}

{phang}{cmd:. sucra, nomv stats("C:\Stata\rank_prob.txt") rprob(effectiveness) name("Unadjusted model") lab("No treatment" Placebo Aspirin)}

{phang}{cmd:. sucra, momv stats("C:\Stata\rank_prob1.txt" "C:\Stata\rank_prob2.txt") rprob(prob) name("Unadjusted model" "Adjusted model") lcol(black blue)}

{phang}

{p}{helpb network_graphs: Return to main help page for the network graphs package}

{phang}

