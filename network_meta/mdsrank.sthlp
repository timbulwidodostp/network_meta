{smcl}

{p}{helpb network_graphs: Return to main help page for the network graphs package}

{hline}
help for {hi:mdsrank}
{hline}

{title:Title}

{p 4 4 2}
Ranking of treatments in networks of interventions using multidimensional scaling


{title:Description}

{p 4 4 1}
It is common when performing a network meta-analysis to rank the competing treatments. Usually, ranking probabilities are used for this purpose (see {helpb sucra}) {help network_graphs##Salanti2011:(Salanti, 2011)}.
A different approach to estimate the relative ranking is the use of multidimensional scaling (MDS) techniques {help network_graphs##Chaimani2013:(Chaimani, 2013)}.
To apply this method, the network estimates for all possible comparisons are treated as proximity data aiming to reveal their latent structure.
In this way the absolute value |mean_XY| defines the dissimilarity between the two treatments (X,Y) with |mean_XX |=0.
Weighting the absolute effects sizes by their inverse standard errors or inverse variances ensures that the assumption of a common distribution between the elements of the matrix is plausible.
Assuming that the rank of the treatments is the only dimension underlying the outcome the purpose of the technique would be to reduce the TxT matrix into a Tx1 vector.
This vector involves the set of distances being as close as possible to the observed dissimilarities (i.e. relative effects) and would represent the relative ranking of the treatments.

{p 4 4 1}
The {cmd:mdsrank} command creates the squared matrix containing the pairwise relative effect sizes and plots the resulting values of the unique dimension for each treatment.


{title:Syntax}

{p 8 17 2}
{cmd:mdsrank} 
{it:varlist}
[{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
[{cmd:,} 
{cmdab:best:(min|max)}
{cmd:noplot}
{cmdab:lab:els(}{it:string}{cmd:)}
{cmdab:scat:teroptions(}{it:string}{cmd:)}

{p 4 4 2}

{p 4 4 1}
The network meta-analysis summary effects and their uncertainty are required as input for this command. These can be provided in two different ways:

{p 4 4 1}
1. By running the {cmd:mdsrank} directly after performing network meta-analysis with {helpb mvmeta} or {helpb network meta}.
Then, the {it:[varlist]} should be omitted. 

{phang}{ul:Important note:} The mdsrank command for this type of input only reads datasets that have been prepared with {helpb network setup} or {helpb network import} in the augmented format{p_end}

{pstd}2. By including these summary estimates as variables in the dataset; the following variables should be specified in [varlist]:{p_end}
{phang}{it:ES} the estimated summary effect for each comparison between two treatments in the network{p_end}
{phang}{it:LCI} and {it:UCI} the lower and upper confidence limits or {it:se} the standard error of each comparisons's {it:ES}{p_end}
{phang}{it:t1} and {it:t2} the two treatments involved in each comparisons {it:ES}{p_end}
{phang}The option {it:nomvmeta} is required.

{title:Options}

{phang}
{cmdab:best:(min|max)} specifies whether larger dimension scores correspond to a more favorable outcome with the treatment. The default option is {bf:min}. 

{phang}
{cmd:noplot} skips the display of the ranking plot.

{phang}
{cmdab:lab:els(}{it:string}{cmd:)} specifies names for competing treatments in the network, which are displayed in the ranking plot.
The treatments should be given in numerical or alphabetical order separated by space.
	 
{phang}
{cmdab:scat:teroptions(}{it:string}{cmd:)} specifies standard options of {helpb scatter}.


{title:Saved results}

{synoptset 20 tabbed}{...}
{synopt:{cmd:e(T)}}the squared matrix with the absolute standardized effect sizes used to perform MDS{p_end}
{synopt:{cmd:e(Y)}}the matrix with the values of the unique dimension for all treatments{p_end}


{title:Examples}

{phang}{cmd:. mdsrank lnOR selnOR treat1 treat2}

{phang}{cmd:. mdsrank, lab(Placebo Aspirin Dipyridamole) scatter(msymbol(square))}

{phang}{cmd:. mdsrank lnOR selnOR treat1 treat2, noplot lab(Placebo Aspirin Dipyridamole)}

{phang} 

{p}{helpb network_graphs: Return to main help page for the network graphs package}

{phang} 

