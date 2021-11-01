# SpotifyFeatures_RapPredictor
Project in R for the "Inferential Statistics" course aimed at predicting if a song is Rap or not through its Spotify features
Evolution of the musical tastes in Italy.
An analysis of the changes in the last 10 years of the yearly top 100 hits.

## Data Collection

From the website Fimi.it we downloaded the data of the weekly charts made of 100 songs from the last 10 years. To build the annual charts we assigned a score to each song based on the position in the charts. The 100 songs with the highest scores built our yearly top 100 hits.
Through the R package rspotify we extracted from the playlists of the top 100 songs of each year the features of each songs: 
- popularity;
- danceability;
- energy;
- loudness (in dB);
- speechiness;
- acousticness;
- instrumentalness;
- liveness;
- valence;
- tempo;
- duration (in ms);

#### Correlation among the features:
![Rplot](https://user-images.githubusercontent.com/93552186/139744798-d6aca82c-790e-461c-b10b-1f84f843f167.png)

#### Exploratory data analysis

From the Shapiro tests we can see that the data are not Normally distributed.

![Rplot01](https://user-images.githubusercontent.com/93552186/139745449-8df8519b-61df-4d96-9491-eeaa0663d64a.png)

It is interesting to take a look at the evolution in time of the boxplots of the features of duration and speechiness:
![Rplot02](https://user-images.githubusercontent.com/93552186/139749165-090264a8-7a36-4fc9-98b1-10e1908a654d.png)
![Rplot03](https://user-images.githubusercontent.com/93552186/139749178-28c92530-2526-46e0-9167-23daba8b3bd5.png)



To go on with the objective of this project, we had to collect more data, so we collected more than 10000 songs from Spotify's playlists based on different genres and from playlists created by musical magazines.
The most meaningful differences between rap and non-rap songs were in the features of speechiness, popularity and danceability, as we can see from the following boxplots (and also the Kruskal-Wallis test confirmed the differences):

![speech](https://user-images.githubusercontent.com/93552186/139745954-cdc36e67-43de-434d-8ca5-16604ce868aa.png)
![popu](https://user-images.githubusercontent.com/93552186/139745978-0b132a19-f503-4058-8b61-f10b98daac29.png)
![dance](https://user-images.githubusercontent.com/93552186/139745989-bb5d5e61-2195-479c-a918-71c5f25981f4.png)

## Logistic Regression

To perform a logistic regression to actually predict whether a song is rap or not, we performed a splitting of the data into a training and a test set. After the first logistic regression, we performed a stepwise selection, discarding one feature at a time with respect to its p-value. The remaining features were popularity, danceability, tempo, acousticness, duration_ms, valence, speechiness and instrumentalness.
The plot of the ROC curve of the training set showed an AUC equal to 0.8996.

![Screenshot (164)](https://user-images.githubusercontent.com/93552186/139747180-ed09a1a3-1b57-4589-8419-8040c6900ddb.png)

We went on with diagnostics and removed the extreme data with respect to the Cook distance and the standardized residuals. In this way, the results improved.

The presentation is in Italian on [Slides](https://slides.com/doncex/spotify).

