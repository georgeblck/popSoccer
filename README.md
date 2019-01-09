README
================

Inspiration
-----------

[This post](https://old.reddit.com/r/soccer/comments/9xvggj/oc_does_a_nations_population_size_predict_the/ "Reddit Link") on reddit was used as inspiration for this body of work (see figure below). The author tries to show the relationship between a nations population and the performance of its soccer team. I like the idea (and the graphic) but see some errors that I wanted to correct:

1.  The FIFA points ranking is a bad measure of a soccer teams actual strength [(Source)](http://lasek.rexamine.com/football_rankings.pdf "Source"). Measures like Elo-rating should be used **and are used** by more sophisticated writers (e.g. 538).
2.  An average of soccer performance should be used (e.g. Average ELO rating of the last 10 years), not a point measurement in time.
3.  The line at 1 million strikes and the coloured bubbles strike me as 100% arbitrary. If anything, a simple clustering algorithm should be used to determine appropriate clusters (e.g. k-means).

![](xiblhhtbvvy11.png)

Results
-------

### Using recent Elo Ratings

First, let us have a look at this graph if we use the World Soccer Elo Rating of December 2017 (pre WorldCup):

    ## # A tibble: 5 x 3
    ##   Country            Code  `Social Progress Index`
    ##   <chr>              <chr>                   <dbl>
    ## 1 Channel Islands    CHI                        NA
    ## 2 Kosovo             KSV                        NA
    ## 3 North Cyprus       NCY                        NA
    ## 4 Somaliland         SML                        NA
    ## 5 West Bank and Gaza WBG                        NA

<img src="README_files/figure-markdown_github/simpleElo17-1.png" width="1000px" />

    ## 
    ##  Kendall's rank correlation tau
    ## 
    ## data:  eloPop$elo17 and eloPop$PopTotal
    ## z = 9.2737, p-value < 0.00000000000000022
    ## alternative hypothesis: true tau is not equal to 0
    ## sample estimates:
    ##       tau 
    ## 0.4118651

We see a much clearer positive correlation between Population and Performance, althoug it fizzes out a both ends of population.

What happens when we insert the countries names <img src="README_files/figure-markdown_github/simpleElo17Names-1.png" width="1000px" /> No we can easily recognize the outliers

-   Better than expected: Iceland, Portugal, Germany, Brazil
-   Worse than expected: Sri Lanka, Bangladesh, India

Iceland and Portugal are the best examples: two small countries that have performed suprisingly well in recent years.

### Using average Elo Ratings

The two positive outliers show, that the graphic is biased on nations that have performed well only in recent years. So let us now look at the Average Elo-Rating:

<img src="README_files/figure-markdown_github/simpleEloAvg-1.png" width="1000px" />

    ## 
    ##  Kendall's rank correlation tau
    ## 
    ## data:  eloPop$avgElo and eloPop$PopTotal
    ## z = 9.3565, p-value < 0.00000000000000022
    ## alternative hypothesis: true tau is not equal to 0
    ## sample estimates:
    ##       tau 
    ## 0.4154963

The correlation stays the same, but we see different outliers:

-   Better than expected: Urugay, Croatia, Scotland
-   Worse than expected:

This also makes sense, as Urugay and Croatia are historically better teams than Iceland & Portugal.

Using more Information
----------------------

### Life Expectancy

What happens when we add more Information to the simple plot

<img src="README_files/figure-markdown_github/lifeElo17-1.png" width="1000px" />

    ## 
    ##  Kendall's rank correlation tau
    ## 
    ## data:  eloPopLife$elo17 and eloPopLife$LEx
    ## z = 4.5485, p-value = 0.000005404
    ## alternative hypothesis: true tau is not equal to 0
    ## sample estimates:
    ##       tau 
    ## 0.2170236

    ## 
    ##  Kendall's rank correlation tau
    ## 
    ## data:  eloPopLife$PopTotal and eloPopLife$LEx
    ## z = -1.9324, p-value = 0.05331
    ## alternative hypothesis: true tau is not equal to 0
    ## sample estimates:
    ##         tau 
    ## -0.09216005

We see that it helps somewhat. Life Expectancy is not correlated with Population but **is** positively correlated with Elo-Rating.

-   Nations above the smoothing line seem to have a higher life expectancy (notable exception: Nigeria, Cameroon)
-   Nations below the line seem to have a lower life expectancy (notable exceptions: Taiwan, Hongkong, Singapore).

### Social Progress Index

We see the same pattern when we use a different measure for the quality of life in a nation:

<img src="README_files/figure-markdown_github/spiElo17-1.png" width="1000px" />

    ## 
    ##  Kendall's rank correlation tau
    ## 
    ## data:  eloPopSPI$elo17 and eloPopSPI$SocialProgressIndex
    ## z = 7.1268, p-value = 0.000000000001027
    ## alternative hypothesis: true tau is not equal to 0
    ## sample estimates:
    ##       tau 
    ## 0.3981661

    ## 
    ##  Kendall's rank correlation tau
    ## 
    ## data:  eloPopSPI$PopTotal and eloPopSPI$SocialProgressIndex
    ## z = -1.5566, p-value = 0.1196
    ## alternative hypothesis: true tau is not equal to 0
    ## sample estimates:
    ##         tau 
    ## -0.08692366

Finding clusters in the data
----------------------------

Let us see now what how we can best group the Population and Elo data.

``` r
library(clValid)
library(factoextra)
library(NbClust)
clusDat <- eloPop[,c("PopTotal", "avgElo")]
rownames(clusDat) <- eloPop$Name
clusDat$PopTotal <- log(clusDat$PopTotal)

intern <- clValid(clusDat, nClust = 2:6, 
              clMethods = c("hierarchical","kmeans","pam"),
              validation = c("internal"),
              metric = "manhattan")
# Summary
summary(intern)
```

    ## 
    ## Clustering Methods:
    ##  hierarchical kmeans pam 
    ## 
    ## Cluster sizes:
    ##  2 3 4 5 6 
    ## 
    ## Validation Measures:
    ##                                  2       3       4       5       6
    ##                                                                   
    ## hierarchical Connectivity   1.6468  4.8758  8.5595 11.0869 14.6782
    ##              Dunn           0.0297  0.0346  0.0346  0.0293  0.0427
    ##              Silhouette     0.5760  0.5384  0.4839  0.5347  0.5256
    ## kmeans       Connectivity   4.4139  8.4972  9.2702 15.0131 20.2067
    ##              Dunn           0.0131  0.0119  0.0292  0.0184  0.0346
    ##              Silhouette     0.5679  0.5607  0.5585  0.5396  0.5507
    ## pam          Connectivity   2.5274 10.2583 15.1980 16.1742 21.5048
    ##              Dunn           0.0151  0.0113  0.0200  0.0213  0.0102
    ##              Silhouette     0.5508  0.5443  0.5354  0.5436  0.5012
    ## 
    ## Optimal Scores:
    ## 
    ##              Score  Method       Clusters
    ## Connectivity 1.6468 hierarchical 2       
    ## Dunn         0.0427 hierarchical 6       
    ## Silhouette   0.5760 hierarchical 2

``` r
set.seed(123)
res.nbclust <- NbClust(clusDat, distance = "manhattan",
                  min.nc = 2, max.nc = 10, 
                  method = "complete", index ="all") 
```

![](README_files/figure-markdown_github/cluster-1.png)

    ## *** : The Hubert index is a graphical method of determining the number of clusters.
    ##                 In the plot of Hubert index, we seek a significant knee that corresponds to a 
    ##                 significant increase of the value of the measure i.e the significant peak in Hubert
    ##                 index second differences plot. 
    ## 

![](README_files/figure-markdown_github/cluster-2.png)

    ## *** : The D index is a graphical method of determining the number of clusters. 
    ##                 In the plot of D index, we seek a significant knee (the significant peak in Dindex
    ##                 second differences plot) that corresponds to a significant increase of the value of
    ##                 the measure. 
    ##  
    ## ******************************************************************* 
    ## * Among all indices:                                                
    ## * 6 proposed 2 as the best number of clusters 
    ## * 10 proposed 3 as the best number of clusters 
    ## * 1 proposed 4 as the best number of clusters 
    ## * 1 proposed 5 as the best number of clusters 
    ## * 3 proposed 7 as the best number of clusters 
    ## * 3 proposed 10 as the best number of clusters 
    ## 
    ##                    ***** Conclusion *****                            
    ##  
    ## * According to the majority rule, the best number of clusters is  3 
    ##  
    ##  
    ## *******************************************************************

``` r
factoextra::fviz_nbclust(res.nbclust) + theme_minimal()
```

    ## Among all indices: 
    ## ===================
    ## * 2 proposed  0 as the best number of clusters
    ## * 6 proposed  2 as the best number of clusters
    ## * 10 proposed  3 as the best number of clusters
    ## * 1 proposed  4 as the best number of clusters
    ## * 1 proposed  5 as the best number of clusters
    ## * 3 proposed  7 as the best number of clusters
    ## * 3 proposed  10 as the best number of clusters
    ## 
    ## Conclusion
    ## =========================
    ## * According to the majority rule, the best number of clusters is  3 .

![](README_files/figure-markdown_github/cluster-3.png)

``` r
# Try out the hierarchical clustering with 2 groups
res <- hcut(clusDat, k = 3, stand = FALSE)
fviz_cluster(res, stand = FALSE, repel = FALSE)
```

![](README_files/figure-markdown_github/cluster-4.png)

``` r
fviz_silhouette(res)
```

    ##   cluster size ave.sil.width
    ## 1       1   90          0.46
    ## 2       2   81          0.69
    ## 3       3   58          0.38

![](README_files/figure-markdown_github/cluster-5.png)

``` r
fviz_dend(res, rect = TRUE)
```

![](README_files/figure-markdown_github/cluster-6.png)

Data Sources
------------

-   ELO: <http://www.eloratings.net>
-   Population Data 2017: <https://population.un.org/wpp/>

### Sources for missing Population data

-   <https://en.wikipedia.org/wiki/Collectivity_of_Saint_Martin>
-   <https://en.wikipedia.org/wiki/Demography_of_England>
-   <https://en.wikipedia.org/wiki/Demography_of_Northern_Ireland>
-   <https://en.wikipedia.org/wiki/Chagos_Archipelago>
-   <https://en.wikipedia.org/wiki/Demography_of_Wales>
-   <https://en.wikipedia.org/wiki/Zanzibar>
-   <https://en.wikipedia.org/wiki/Bonaire>
-   <https://de.wikipedia.org/wiki/Saint-Barth%C3%A9lemy_(Insel)>
