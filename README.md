# GIS3 Final
### By Grey Moszkowski
###### Final Project for GIS 3 at the University of Chicago
###### 5/27/2022

## Background and Motivation
The Russo-Ukrainian War of 2022 has lasted far longer than military analysts predicted. Many observers believed that Russia’s forces would quickly capture Kyiv and install a puppet government. So far, that has not happened; in fact, Ukrainian forces have succeeded in pressing most Russian troops back to the eastern part of the country. A major reason for this strong resistance has been Russia’s inability to establish complete control over the skies. Although Russia enjoys an advantage in both quantity and quality of aircraft, Ukraine’s persistent and intelligent application of ground-to-air weapons systems has frustrated Russian efforts to dominate the air. Russia’s inability to afford many laser-guided and other precision munitions has required Russian aircraft to fly low to hit their targets, allowing anti-air systems to fire effectively. Ukrainian pilots, though flying older jets, have been able to deny airspace to Russian aircraft despite flying far few sorties per day. 

The trend of Ukrainian resistance in the skies is one of the most important determinants of the course of the war. As such, mapping it is important to understanding the conflict. Visualizing the effectiveness of Russian airstrikes and Ukrainian anti-air defense is a key part of understanding the progression and development of the war. 
I additionally was motivated by a desire to examine the Russian claim that the invasion was justified by a need to protect "ethnic Russians" in Ukraine, especially in the country's East. Given this justification, I am interested in examining the extent to which the Russian air war is affecting the areas that are majority Russian-speaking. I use majority Russian-speaking areas as a proxy for "Russian ethnicity," since I am not aware of any other useful proxy for that psuedo-variable. 

## Goals and Objectives
My goals are:
1. Create a hexbinned map of Ukrainian-instigated anti-aircraft events in relation to oblast-level linguistic data.
2. Create a hexbinned map of Russian-instigated airstrikes in relation to oblast-level linguistic data.
3. Create a choropleth map of Ukranian oblasts based on a metric of Effective Air Defense (EAD) that I will calculate.

## Data Sources and Scale
The central data in this project comes from Professor Yuri Zhukov's Violent Incident Information from News Articles (VIINA) Project. Professor Zhukov is a political scientist at the University of Michigan whose [VIINA project](https://github.com/zhukovyuri/VIINA) combs Ukranian- and Russian-language news sources for information on violent incidents related to the war. The VIINA dataset is wide-ranging. It codes for events ranging from firefights and airstrikes to territorial claims and civilian protests. It includes detailed coding conventions with dummy variables that allow for easy filtering of certain types of events for analysis. Crucially, it also includes latitude and longitude data for each event, giving me the basis for my spatialized analysis. 

In terms of spatial scale, the VIINA dataset is compiled on the incident scale. Each incident receives its own row. In terms of temporal scale, the data stretches back to the first day of the war and appears to be updated daily (the history of Professor Zhukov's [Data repo](https://github.com/zhukovyuri/VIINA/commits/master/Data) shows daily commits to the VIINA data). The VIINA dataset is therefore a live open-source dataset that appears to be attended to quite actively. As a live dataset, my visualizations will quickly become outdated as new data is added. My code, attached to this repo, will reproducibly recreate the datasets I used to make my visualizatiions with updated data. The visualizations in this repo were made with all the available data as of 5/27/2022. 

The linguist dataset I used was from [humdata.org](https://data.humdata.org/dataset/ukraine-languages), which itself sourced the data from the [2001 Ukrainian Census](http://2001.ukrcensus.gov.ua/eng/). There has not been another nationwide census since 2001. The dataset I used came at the oblast level.

I sourced a shapefile of oblast boundaries from the [University of Texas GeoData Library](https://geodata.lib.utexas.edu/?f%5Bdc_format_s%5D%5B%5D=Shapefile&f%5Bdct_spatial_sm%5D%5B%5D=Ukraine&f%5Blayer_geom_type_s%5D%5B%5D=Polygon&per_page=100&sort=score+desc%2C+dc_title_sort+asc). I sourced a dataset of Ukranian cities (of which I only plotted ten) from [simplemaps.com](https://simplemaps.com/data/ua-cities). 

## Methods Used
I used R Studio to wrange my data and [kepler.gl](https://kepler.gl/) to visualize it.

To create my anti-air event and airstrike event data, I did the following:

- Import VIINA data using download.file(url) for reproducibility and read the data into R.
- Spatialize the data using st_as_sf().
- Clean the data by removing extraneous columns using subset().
- Write VIINA data to a geoJSON file.
- Use dplyr::filter() to extract Ukrainian anti-air (aa) and Russian airstrike (strike) events. 
- Write filtered aa and strike data to geoJSON files.

Later, when mapping my work in Kepler, I realized that no matter the spatial data type contained in the geoJSON file, Kepler recognizes the contents of a geoJSON as a polygon. This meant that Kepler saw the anti-air and airstrike points as polygons, making it impossible for me to hexbin them. As such, I needed to provide Kepler a CSV file of the relevant points that included latitude and longitude columns. I did this by repeating the steps above but skipping the spatializing step and writing to CSV files instead of geoJSON files. I fed those CSV files to Kepler and it plotted the points from the lat/long columns. 

To create my spatialized oblast-level linguistic dataset, I did the following:

- Read in oblast boundary shapefile.
- Clean the boundary shapefile by removing irrelevent columns using subset().
- Read in oblast linguistic data using read.csv(url()). 
- Clean oblast linguistic data using subset(). 

The next step was to combine the oblast boundaries with the oblast-level linguistic data. The trouble was that there was no easily-usable key variable with which to perform a join. Because the oblast names in each dataset are English transliterations from Ukrainian, which uses a different alphabet, they were spelled differently. Some included commas where other transliterations did not. The spellings were so different, in fact, that even when placed in simple alphabetical order, the rows of the two datasets did not line up. I circumvented this issue by manually creating a **name** column in my oblast-level linguistic data with names that were spelled exactly as the names in the oblast boudnary shapefile were. I then alphabetized both datasets based on the shared **name** column, added an ID_1 column in the linguistic dataset to match the one in the oblast boundary dataset, and joined the two based on that. 

From there, I needed to construct my metric of effective air defense (EAD). I did so on the oblast level by counting the number of aa and airstrike events in each oblast and dividing each oblast's total aa events by its total airstrike events. The resulting value represents EAD; the higher the value, the higher the ratio between effective anti-air events and Russian airstrikes. 

I used Kepler to create three maps from the resultant data. The first two were hexbin maps of the distribution of aa events and strike events, respectively. Those hexbins were overlayed over a choropleth map of oblast-level linguistic data; the color of each oblast depended on the majority language spoken. The third map was a choropleth map of each oblast's EAD. I included labeled points representing the ten largest cities in Ukraine as well, to provide some context. 

## Results

The following are screenshots of my three maps. I have also included the html files of these maps in this repo. I highly recommend downloading and opening them rather than just looking at the screenshots, since there are interactive elements of the maps that aid analysis. Clicking on each hexbin, city point, or oblast polygon gives more information about the object in question. 

AA Events:
<img width="1280" alt="Screen Shot 2022-05-27 at 5 06 04 PM" src="https://user-images.githubusercontent.com/101352812/170795032-8b22ec86-9a98-40a5-8aea-01523196c078.png">

Airstrike Events:
<img width="1263" alt="Screen Shot 2022-05-27 at 5 06 19 PM" src="https://user-images.githubusercontent.com/101352812/170795047-766a7c34-03da-4a63-8f67-3d0d05b014ce.png">

EAD:
<img width="1197" alt="Screen Shot 2022-05-27 at 5 06 34 PM" src="https://user-images.githubusercontent.com/101352812/170795058-0d565d61-1c9b-4898-bece-b30bf9726732.png">

## Discussion of Results
Perhaps unsurprisingly, it appears that the majority of airstrikes and anti-air events are concentrated in the Kyiv, Donetsk, and Lukhansk areas. These areas are where most of the fighting has been taking place. They are generally considered the key areas in the war. Kyiv is the Ukranian capital and the center of its political and military command, while Donetsk and Lukhansk border against Russia. As the underlying choropleth shows, Donetsk and Lukhansk are also two of the four oblasts which have a majority of Russian-speakers (one of the four, Crimea, was annexed by Russia in 2014). Most of the anti-air events are concentrated in those key areas. 

In contrast, the data demonstrates that there are many more airstrike events than anti-air events. The visualization reflects this and shows that the airstrikes are not just more numerous but more widespread than the anti-air events. Russian airstrikes pop up deep into Ukraine's western regions, far from the battlefield "hot spots" of Kyiv and the East. Anti-air events do not do so. This spatial organization demonstrates two things - one, that Russia does mostly control the skies over Ukraine (although that control is not unchallenged), and two, that Ukraine does not have enough effective anti-air systems to counter the scale of the Russian air war. The data suggests that Ukraine has concentrated its air defense systems in the key areas of Kyiv, Donetsk, and Lukhansk, which makes good military sense. 

In terms of the EAD map, there does not appear to be significant spatial correlations between the oblasts with relatively high EAD scores. The city of Kyiv and the oblasts of Donetsk, Lukhansk, and their eastern neighbor Kharkhiv have relatively high scores, demonstrating a limited correlation between strategic value and EAD. This agrees with the findings from the first two maps; the implication is that Ukraine is positioning its anti-air systems in strategically important regions and leaving other regions (especially in the West) more vulnerable to Russian airpower. 

## Limitations: 
One main limitation of this project is its scale. I used oblasts, the first-level administrative division, as my scale. Ideally, I would have used second-level administrative divisions to avoid potential aggregation problems that could lead to misleading takeaways. However, second-level divisions would have been very hard to work with given the difficulty I encountered merging the division boundaries with the division-level linguistic data. Doing so with 27 oblasts was hard enough; the spelling discrepancies between hundreds of second-level divisions would have been very hard to work with. Future work could address this by taking the time to harmonize these datasets. 

Future work could also focus on the destructiveness of Russian airstrikes. VIINA contains dummy variables that represent civilian and military casualties. If I were to extend this project, I would use those variables to examine the spatial distribution of casualities related to the airstrikes. I'm not sure if such data exists, but I would like to assess the accuracy of Russian airstrikes as well; because Russia does not have advanced guided munitions, many of their airstrikes are inaccurate. I would like to visualize the innacuracy in a future project. I would also attempt to integrate other types of events, such as territorial claims, armor strikes, firefights, etc. into the analysis. Finally, I would attempt to temporalize the data (the "date" column was in an integer format) and create a GIF of the week-by-week progression of the air war. All of these steps would increase our understanding of the conflict's progression and the effect of the air war on the conflcit overall. 

## Conclusion
In the early days of the war, social media spread the legend of the "Ghost of Kyiv," a Ukranian ace pilot who, flying an outdated MiG-29, shot down six or seven Russian jets in the first days of the war. The story was incredibly popular, inspiring Ukranians and supporters around the world to believe in the Ukranian resistance. The  story was also fiction. 

The Ghost of Kyiv did not exist. However, he played a large part in the creation of the narrative of the Ukranian resistance. To be clear, this narrative is well-earned and mostly truthful. Ukraine has performed better than expected in the air war, and will probably perform even better in the future as soldiers adapt and receive more anti-air systems from Western backers. However, Ukraine remains vastly outnumbered and outgunned in the air. My visualizations reflect that. In sketching an overview of the spatial distribution of key events during the air war, my project provides a clear reminder that Ukraine remains the underdog in the skies.


