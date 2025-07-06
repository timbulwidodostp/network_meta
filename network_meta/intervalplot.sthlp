{smcl}

{p}{helpb network_graphs: Return to main help page for the network graphs package}

{hline}
help for {hi:intervalplot} command
{hline}

{title:Title}

{p 4 4 2}
{title:Confidence & Predictive intervals plot}

{title:Description}

{p 4 4 1}
The extend of uncertainty in the estimated treatment effects in meta-analysis is reflected not only by the confidence intervals but also by the predictive intervals that incorporate the extend of heterogeneity 
{help network_graphs##Riley2011:(Riley, 2011)},
{help network_graphs##Higgins2009:(Higgins, 2009)}.
The predictive interval is the interval within which the estimate of a future study is expected to lie. In a network meta-analysis usually a common heterogeneity estimate is assumed for all pairwise comparisons. However, its impact across the different comparisons
might be variable (i.e. it can affect only the precision of the estimates or also the direction).  

{p 4 4 1}
The {cmd:intervalplot} command plots plots the estimated effect sizes and their uncertainty for all pairwise comparisons in a network meta-analysis.
More specifically, it produces a forest plot where the horizontal lines representing the confidence intervals are extended to show simultaneously the predictive intervals. 
The treatment effects and their uncertainty can be estimated either within Stata using {helpb mvmeta} or {helpb network} command {help network_graphs##White2011:(White, 2011)},
{help network_graphs##White2012:(White, 2012)}, {help network_graphs##White2013:(White, 2013)} or using other software.

{title:Syntax}

{p 8 17 2}
{cmd:intervalplot} 
{it:[varlist]}
[{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
[{cmd:,} 
{cmdab:mvmeta:results}
{cmdab:nomv:meta}
{cmdab:pred:ictions}
{cmdab:eform}
{cmdab:rev:erse}
{cmdab:lab:els(}{it:treatment_labels|label_var}{cmd:)}
{cmdab:ref:erence(}{it:reference_treatment}{cmd:)} 
{cmdab:noval:ues}
{cmd:null(}{it:#}{cmd:)}
{cmdab:nullopt:ions(}{it:line_options}{cmd:)}
{cmdab:fcicol:or(}{it:string}{cmd:)}
{cmdab:scicol:or(}{it:string}{cmd:)}
{cmdab:fcipat:tern(}{it:string}{cmd:)}
{cmdab:scipat:tern(}{it:string}{cmd:)}
{cmdab:symb:ol(}{it:string}{cmd:)}
{cmdab:r:ange(}{it:string}{cmd:)}
{cmdab:xtitle:(}{it:string}{cmd:)}
{cmdab:xlab:el:(}{it:string}{cmd:)}
{cmdab:labt:itle(}{it:string}{cmd:)}
{cmdab:valuest:itle(}{it:string}{cmd:)}
{cmdab:symbols:ize(}{it:string}{cmd:)}
{cmdab:texts:ize(}{it:string}{cmd:)}
{cmdab:lw:idth(}{it:string}{cmd:)}
{cmdab:mar:gin(}{it:# # # #}{cmd:)}
{cmdab:tit:le(}{it:string}{cmd:)}
{cmdab:notab:le}
{cmd:noplot}
{cmd:keep}]

{p 4 4 2}

{p 4 4 1}
The network meta-analysis summary effects and their uncertainty are required as input for this command. These can be provided in two different ways:

{p 4 4 1}
1. By running the {cmd:intervalplot} directly after performing network meta-analysis with {helpb mvmeta} or {helpb network meta}.
Then, the option {it:mvmetaresults} may be specified ({bf:the default}) and the {it:[varlist]} should be omitted. 

{phang}{ul:Important note:} The intervalplot command for this type of input only reads datasets that have been prepared with {helpb network setup} or {helpb network import} in the augmented format{p_end}

{pstd}2. By including these summary estimates as variables in the dataset; the following variables should be specified in [varlist]:{p_end}
{phang}{it:ES} the estimated summary effect for each comparison between two treatments in the network{p_end}
{phang}{it:LCI} and {it:UCI} the lower and upper confidence limits of each comparisons's {it:ES}{p_end}
{phang}Optionally we can additionally specify the variables {it:LPI} and {it:UPI} the predictive lower and upper limits of each comparisons's {it:ES}{p_end}
{phang}The option {it:nomvmeta} is required.

{title:Options} 

{phang}
{cmdab:pred:ictions} specifies that the predictive intervals are added in the plot (when the option {it:nomvmeta} has not been specified; in the default plot only the confidence intervals are displayed).

{phang}
{cmdab:eform} specifies that the results are displayed on the exponential scale.

{phang}
{cmdab:rev:erse} reverses the direction of all effect sizes in the output and the plot.

{phang}
{cmdab:lab:els()} specifies names for competing treatments in the network, which are displayed in the plot and the output results. Depending on the input, the treatments should be given in the following ways:

{p 8 8 1}
{cmd:{it:treatments}} When the option {it:nomvmeta} has not been specified: the first treatment in {it:labels()} should be the treatment assumed the reference when running the {cmd:mvmeta} or {cmd:network}
and the following treatments should be given in numerical or alphabetical order. 

{p 8 8 1}
{cmd:{it:comparison}} When the option {it:nomvmeta} has been specified: the variable with the names of the comparisons corresponding to the confidence and predictive intervals in the dataset.

{phang}
{cmdab:ref:erence(}{it:reference_treatment}{cmd:)} specifies that only the relative effects of each treatment vs. the {it:reference_treatment} are displayed
(when {it:labels()} has been specified). 

{phang}
{cmdab:noval:ues} suppresses the display of the numerical estimates and their uncertainty in the plot.

{phang}
{cmd:null(}{it:#}{cmd:)} specifies the value for the line of no effect.

{phang}
{cmdab:nullopt:ions(}{it:line_options}{cmd:)} specifies the options for the line of no effect (see {helpb line}).

{phang}
{cmdab:fcicol:or(}{it:string}{cmd:)} specifies the color for the lines representing the confidence intervals.

{phang}
{cmdab:scicol:or(}{it:string}{cmd:)} specifies the color for the lines representing the predictive intervals.

{phang}
{cmdab:fcipat:tern(}{it:string}{cmd:)} specifies the pattern for the lines representing the confidence intervals.

{phang}
{cmdab:scipat:tern(}{it:string}{cmd:)} specifies the pattern for for the lines representing the predictive intervals.

{phang}
{cmdab:symb:ol(}{it:string}{cmd:)} specifies the symbol for the point summary estimates ({it:ES}). 

{phang}
{cmdab:r:ange(}{it:string}{cmd:)} specifies the range of values plotted in the horizontal axis.

{phang}
{cmdab:xtitle:(}{it:string}{cmd:)} specifies a title for the horizontal axis.

{phang}
{cmdab:xlab:el:(}{it:string}{cmd:)} specifies the values displayed in the horizontal axis.

{phang}
{cmdab:labt:itle(}{it:string}{cmd:)} specifies the title for the labels of comparisons displayed in the plot.

{phang}
{cmdab:valuest:itle(}{it:string}{cmd:)} specifies a title for the numerical values of the summary estimates and their uncertainty.

{phang}
{cmdab:symbols:ize(}{it:string}{cmd:)} specifies the size for the symbol of the point summary estimates ({it:ES}).

{phang}
{cmdab:texts:ize(}{it:string}{cmd:)} specifies the size for the text in the plot.

{phang}
{cmdab:lw:idth(}{it:string}{cmd:)} specifies the width for the lines representing the confidence and predictive intervals.

{phang}
{cmdab:mar:gin(}{it:# # # #}{cmd:)} specifies the margins for the region of the plot (see {helpb margin}).

{phang}
{cmdab:tit:le(}{it:string}{cmd:)} specifies the title for the plot.

{phang}	
{cmdab:notab:le} skips the display of the output results.

{phang}	
{cmd:noplot} skips the display of the plot.

{phang}
{cmd:keep} specifies that the results are stored as additional variables in end of the dataset.


{title:Examples}

{phang}{cmd:. intervalplot, eform}

{phang}{cmd:. intervalplot, eform lab(A B C D) predictions ref(B) null(1)}

{phang}{cmd:. intervalplot lnOR LCI_lnOR UCI_lnOR, nomv lab(comparison)}

{phang}{cmd:. intervalplot lnOR LCI_lnOR UCI_lnOR LPI_lnOR UPI_lnOR, nomv lab(treatment1 treatment2)}


{title:Details}

{p 0 0 0}
In case the predicted intervals are estimated using the results derived from network meta-analysis with {helpb mvmeta} or {helpb network}, 
a t-distribution is assumed for the summary treatment effect estimates. The degrees of freedom are computed as the the total number of studies
minus the number of direct comparisons with data minus 1 {help network_graphs##Cooper2009:(Cooper, 2009)}.

{phang} 

{p}{helpb network_graphs: Return to main help page for the network graphs package}


{phang} 
