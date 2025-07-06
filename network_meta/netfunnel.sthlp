{smcl}

{p}{helpb network_graphs: Return to main help page for the network graphs package}

{hline}
help for {hi:netfunnel} command
{hline}

{title:Title}

{p 4 4 2}
'Comparison-adjusted funnel plot' for a network of interventions


{title:Description}

{p 4 4 1}
Funnel plots are commonly used in pairwise meta-analysis to assess the presence of small-study effects (important differences in treatment effect estimates between small and large studies).
A funnel plot is a scatterplot of a measure of precision (e.g. standard error or variance) vs. the estimated treatment effect for each study. If the study estimates are lying symmetrically
around the line of the meta-analysis summary effect then the funnel plot suggest no evidence of small-study effects.

{p 4 4 1}
Differences in the relative effects between small and large trials in a network of interventions often challenge the interpretation of the pairwise summary effects and need exploration.g the funnel plot from pairwise to network meta-analysis needs to account for the fact that different treatment comparisons are included and each comparison has its own summary effect;
hence there is not a common reference line of symmetry for all the studies in the network. In the comparison-adjusted funnel plot the horizontal axis shows the difference of each {it:i}-study's estimate {it:y_iXY} from the
summary effect for the respective cpomparison ({it:y_iXY-mu_XY}), while the vertical axis presents a measure of dispersion of {it:y_iXY}.
In the absence of small-study effects all studies are expected to lie symmetrically around the zero line of the comparison-adjusted funnel plot {help network_graphs##Chaimani2012:(Chaimani, 2012)},
{help network_graphs##Chaimani2013:(Chaimani, 2013)}.
Obtaining meaningful conclusions from this graph requires to define all comparisons across studies in a consistent direction,
such as active intervention vs. inactive, newer treatment vs. older, sponsored vs. non-sponsored, etc.
  
{p 4 4 1}
The {cmd:netfunnel} command plots a comparison-adjusted funnel plot for assessing small-study effects within a network of interventions.
The command plots observations using a different color per comparison.
The default direction for all comparisons in the network is in alphabetical or numerical order based on the codes of the treatments that appear in the dataset (i.e. A vs. B, B vs. C, A vs. C, 1 vs. 2, 2 vs. 3 etc.).
Investigators should order the treatments in a meaningful way rather than using the default ordering. 
For example, the codes of the treatments could be chosen to order them from the older to the newest. 
	

	
{title:Syntax}

{p 8 17 2}
{cmd:netfunnel} 
{it:varlist}
[{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
[{cmd:,} 
{cmd:fixed}
{cmd:random}
{cmdab:bycomp:arison}
{cmdab:add:plot(}{it:string}{cmd:)}
{cmdab:xtit:le(}{it:string}{cmd:)}
{cmdab:ytit:le(}{it:string}{cmd:)}
{cmdab:xlab:el(}{it:string}{cmd:)}
{cmdab:ylab:el}{it:string}{cmd:)}
{cmdab:scat:teroptions(}{it:string}{cmd:)}
{cmd:noci}
{cmdab:ord:er}{it:string}{cmd:)}

{p 4 4 2}

{p 4 4 1}
The netfunnel command requires in {it:varlist} to specify the following variables:

{pstd}{it:ES} the effect sizes for every treatment comparison defined in the dataset (for ratio 
measures such as odds ratio, risk ratio, hazard ratio, etc. the effect sizes in {it:ES} should be in logarithmic scale; e.g. log-odds ratio, log-risk ratio){p_end} 
{phang}{it:se} the standard errors of the effect sizes in {it:ES}{p_end} 
{phang}{it:t1} and  {it:t2} (numeric or string) the codes of the two treatments compared in each observation. 
specifying {it:t1} first means that the effect sizes have been estimated as {it:t1} vs. {it:t2},
whereas specifying {it:t1} second means that the direction of the effect sizes is {it:t2} vs. {it:t1}.
This does not affect the appearance of the comparison-adjusted funnel plot, but the interpretation of the graph depends on the direction of the relative effects.{p_end} 

{phang}{ul:Important note:} The netfunnel command only reads datasets that have been prepared with {helpb network setup} or {helpb network import} in the pairs format{p_end}

{title:Options}

{phang}
{cmd:fixed} specifies that the fixed effect model is used to estimate the direct summary effects ({bf:the default}).

{phang}
{cmd:random} specifies that the random effects model is used to estimate the direct summary effects.

{phang}
{cmdab:bycomp:arison} specifies that different colors are used for the different pairwise comparisons.

{phang}
{cmdab:ord:er}{it:string}{cmd:)} specifies that the comparisons are included in the plot as: treatment first in specified order vs. treatment second in specified order.
When this option is omitted the comparisons are included in the plot as: treatment first in alphabetical order vs. treatment second in alphabetical order.

{phang}
{cmdab:add:plot(}{it:string}{cmd:)} specifies the addition of other {helpb twoway} graphs.

{phang}
{cmd:noci} specifies that the pseudo 95% confidence interval lines for the difference (y_iXY-mu_XY) are not included in the plot.

{phang}
{cmdab:xtit:le(}{it:string}{cmd:)} specifies the title for the horizontal axis.

{phang}
{cmdab:ytit:le(}{it:string}{cmd:)} specifies the title for the vertical axis.

{phang}
{cmdab:xlab:el(}{it:string}{cmd:)} specifies the values displayed in the horizontal axis.

{phang}
{cmdab:ylab:el(}{it:string}{cmd:)} specifies the values displayed in the vertical axis.
	
{phang}
{cmdab:scat:teroptions(}{it:string}{cmd:)} specifies standard options of {helpb scatter}.


{title:Saved results}

{pstd}{cmd:netfunnel} adds a variable named _ES_CEN in the end of the dataset containing the study effect sizes centered at the comparison-specific summary effect(y_iXY-mu_XY). 

{synoptset 20 tabbed}{...}
{synopt:{cmd:e(R)}}the matrix containing the observations with reversed effect sizes{p_end}


{title:Examples}

{phang}{cmd:. netfunnel lnOR selnOR treat1 treat2, order(A C E D)}

{phang}{cmd:. netfunnel SMD seSMD treat1 treat2, bycomp addplot(lfit seSMD _ES_CEN)}

{phang}

{p}{helpb network_graphs: Return to main help page for the network graphs package}

{phang} 
