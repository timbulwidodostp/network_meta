{smcl}

{p}{helpb network_graphs: Return to main help page for the network graphs package}

{hline}
help for {hi:clusterank} command
{hline}

{title:Title}

{p 4 4 2}
Clustering for treatments of a network of interventions according to their performance on two outcomes


{title:Description}

{p 4 4 1}
When performing a network meta-analysis the competing treatments can be ranked according to their performance on one or more outcomes (e.g. effectiveness and safety).
However, the relative ranking for each outcome might be different and this makes the choice of the 'best' treatment challenging.
A possible way to make inferences based on results for two outcomes is by using a two-dimensional plot and constructing groups of treatments with similar performance on both outcomes {help network_graphs##Chaimani2013:(Chaimani, 2013)}.
To form meaningful groups of treatments, hierarchical clustering methods have been employed. 

{p 4 4 1}
The {cmd:clusterank} command performs hierarchical cluster analysis to group the competing treatments in meaningful groups.
It requires the values of a ranking measure (e.g. SUCRA percentages or MDS dimension; see {helpb sucra}, {helpb mdsrank}) for two outcomes.


{title:Syntax}

{p 8 17 2}
{cmd:clusterank} 
{it:varlist}
[{cmd:,} 
{cmdab:best:(min|max)}
{cmdab:meth:od(}{it:linkage_method distance_metric}{cmd:)}
{cmdab:cl:usters(}{it:intger}{cmd:)}
{cmdab:scat:teroptions(}{it:string}{cmd:)}
{cmdab:den:rogram}

{p 4 4 2}

{p 4 4 1}
The clusterank command requires in {it:varlist} to specify the following variables:

{pstd}{it:outcome1} and {it:outcome2} the estimated values of a ranking measure for two different outcomes{p_end}

{phang}Optionally we can additionally specify the variable {it:t} (numerical or string) the names pf the competinf treatments in the network{p_end}

{phang}Note: if the variable {it:t} has not been specified, the treatments are named according to the observation numbers.{p_end}


{title:Options}

{phang}
{cmdab:best:(min|max)} specifies whether larger or smaller values of the ranking measure correspond to better outcome with the treatment (applies to both outcomes).
The default option is {bf:max}. 

{phang}
{cmdab:meth:od(}{it:linkage_method distance_metric}{cmd:)} specifies which {it:linkage method} and {it:distance metric} are used (see {helpb cluster}). By default, the method of hierarchical clustring
is decided according to the cophenetic correlation coefficient {help network_graphs##Handl2005:(Handl, 2005)}.

{phang}
{cmdab:cl:usters(}{it:intger}{cmd:)} specifies the number of clusters used to group the treatments. By default, the optimal number of clusters is decided according to the
'clustering gain' {help network_graphs##Jung2003:(Jung, 2003)}.
	
{phang}
{cmdab:scat:teroptions(}{it:string}{cmd:)} specifies standard options of {helpb scatter}.

{phang}
{cmdab:dend:rogram} specifies that the dendrogram of the hierarchical analysis is displayed instead of the clustered ranking plot.


{title:Examples}

{phang}{cmd:. clusterank outcome1 outcome2 treat, method(singlelinkage Euclidean) clusters(5)}

{phang}{cmd:. clusterank outcome1 outcome2, scatter(msymbol(square))}

{phang}{cmd:. clusterank outcome1 outcome2 t, dendrogram}

{title:Details}

{p 0 0 0}

The command chooses the appropriate metric (Euclidean, squared Euclidean, absolute-value distance, etc.) and linkage method (single, average, weighted, complete, ward, centroid, median)
based on the cophenetic correlation coefficient, which measures how faithfully the output dendrogram represents the dissimilarities between observations {help network_graphs##Handl2005:(Handl, 2005)}.
The optimal level of dendrogram and the optimal number of clusters are chosen using an internal cluster validation measure, called 'clustering gain' {help network_graphs##Jung2003:(Jung, 2003)}.
This measure has been designed to have a maximum value when intra-cluster similarity is maximized and inter-cluster similarity is minimized.

{phang} 

{p}{helpb network_graphs: Return to main help page for the network graphs package}

{phang} 

