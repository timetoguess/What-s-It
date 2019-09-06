# Time to Guess App
A guessing game powered by AI!

Time To Guess downloads an image from the Internet and uses artificial intelligence to select a random object! Get some clues and take a guess 😊

## Background
This summer I noticed that my kids and nephews (elementary through high school) were playing the guess name - one of them selected (in mind) an object in the room and others tried to guess it by asking Yes/No type questions to that person. I thought this would be a fun application of object detection in AI, and hence this project! Not that I wanted to increase their screen time 😜

## Usage
Take the fun of guess game to the next level with Time To Guess app - Powered by AI!

Time To Guess downloads a random image from the Internet, uses AI object detection to determine different objects in the image, and selects a random object.

Your part is to guess which object in the image has the app selected! Feel free to get some clues and then take a guess 😊

When you click on a clue in the Clues scene, the color of clue changes: Green is Yes and Gray is No.

Every clue used and an incorrect guess takes away some points. Also, the longer time you take in making the correct guess, the more points you loose.

Guess the selected object in minimum time and with minimum clues and incorrect guesses!

If WiFi and mobile broadband isn’t available, the app uses one of the images included in the app package.

You can also select images from your phone or take a new photo and the app will select a random object! By the way, don't worry - your images will not be stored or sent to a server.

Remember, AI is still learning and sometimes makes mistakes (e.g. a cup for a glass)… For those interested, the model used is YOLOv3 (Int8). Regular model (rather than tiny) is used for higher accuracy.

Your comments and feedback are welcome!

Happy guessing! Enjoy - Time To Guess!

## Screen Captures
<img src="https://github.com/timetoguess/What-s-It/blob/master/Screen%20Captures/v1.2/5.5%20Inch/Simulator%20Screen%20Shot%20-%20iPhone%208%20Plus%20-%202019-09-01%20at%2019.20.26.png" width="124" height="220"> <img src="https://github.com/timetoguess/What-s-It/blob/master/Screen%20Captures/v1.2/5.5%20Inch/Simulator%20Screen%20Shot%20-%20iPhone%208%20Plus%20-%202019-09-01%20at%2017.16.00.png" width="124" height="220">
<img src="https://github.com/timetoguess/What-s-It/blob/master/Screen%20Captures/v1.2/5.5%20Inch/Simulator%20Screen%20Shot%20-%20iPhone%208%20Plus%20-%202019-09-01%20at%2017.16.05.png" width="124" height="220">
<img src="https://github.com/timetoguess/What-s-It/blob/master/Screen%20Captures/v1.2/5.5%20Inch/Simulator%20Screen%20Shot%20-%20iPhone%208%20Plus%20-%202019-09-01%20at%2017.16.34.png" width="124" height="220">
<img src="https://github.com/timetoguess/What-s-It/blob/master/Screen%20Captures/v1.2/6.5%20Inch/Simulator%20Screen%20Shot%20-%20iPhone%20Xs%20Max%20-%202019-09-01%20at%2001.22.05.png" width="124" height="220">
<img src="https://github.com/timetoguess/What-s-It/blob/master/Screen%20Captures/v1.2/5.5%20Inch/Simulator%20Screen%20Shot%20-%20iPhone%208%20Plus%20-%202019-09-01%20at%2017.16.54.png" width="124" height="220">
<img src="https://github.com/timetoguess/What-s-It/blob/master/Screen%20Captures/v1.2/5.5%20Inch/Simulator%20Screen%20Shot%20-%20iPhone%208%20Plus%20-%202019-09-01%20at%2017.16.58.png" width="124" height="220">
<img src="https://github.com/timetoguess/What-s-It/blob/master/Screen%20Captures/v1.2/5.5%20Inch/Simulator%20Screen%20Shot%20-%20iPhone%208%20Plus%20-%202019-09-01%20at%2017.17.20.png" width="124" height="220">
<img src="https://github.com/timetoguess/What-s-It/blob/master/Screen%20Captures/v1.2/5.5%20Inch/Simulator%20Screen%20Shot%20-%20iPhone%208%20Plus%20-%202019-09-01%20at%2017.21.15.png" width="124" height="220">
<img src="https://github.com/timetoguess/What-s-It/blob/master/Screen%20Captures/v1.2/5.5%20Inch/Simulator%20Screen%20Shot%20-%20iPhone%208%20Plus%20-%202019-09-01%20at%2019.08.26.png" width="124" height="220">
<img src="https://github.com/timetoguess/What-s-It/blob/master/Screen%20Captures/v1.2/5.5%20Inch/Simulator%20Screen%20Shot%20-%20iPhone%208%20Plus%20-%202019-09-01%20at%2019.09.54.png" width="124" height="220">
<img src="https://github.com/timetoguess/What-s-It/blob/master/Screen%20Captures/v1.2/5.5%20Inch/Simulator%20Screen%20Shot%20-%20iPhone%208%20Plus%20-%202019-09-01%20at%2019.19.35.png" width="124" height="220">
<img src="https://github.com/timetoguess/What-s-It/blob/master/Screen%20Captures/v1.2/6.5%20Inch/Simulator%20Screen%20Shot%20-%20iPhone%20Xs%20Max%20-%202019-09-01%20at%2001.21.39.png" width="124" height="220">
<img src="https://github.com/timetoguess/What-s-It/blob/master/Screen%20Captures/v1.2/6.5%20Inch/Simulator%20Screen%20Shot%20-%20iPhone%20Xs%20Max%20-%202019-09-01%20at%2001.26.34.png" width="124" height="220">
<img src="https://github.com/timetoguess/What-s-It/blob/master/Screen%20Captures/v1.2/6.5%20Inch/Simulator%20Screen%20Shot%20-%20iPhone%20Xs%20Max%20-%202019-09-01%20at%2001.35.43.png" width="124" height="220">

## Usage Video on YouTube
[![Sample Usage Video](https://i.ytimg.com/vi/Cpp0Vcro1QE/1.jpg)](https://youtu.be/Cpp0Vcro1QE)

## Required Changes to the Source Code
The source code has the project What's It. Since the app name was already taken, the app has been published as Time to Guess!
### Add your Pexels API key to download the images
The online images are downloaded using Pexels API (https://www.pexels.com). According to the Pexels website:
* All photos on Pexels are free to use.
* Attribution is not required. Giving credit to the photographer or Pexels is not necessary but always appreciated.

Thanks to Pexels for making these images available for download. In the user interface of the app, credit is displayed to Pexels and the photographer.

You will need to register with Pexels to get your API key. After that, rename the SecretShared.swift file to Secret.swift and replace the string "USE YOUR PEXELS API KEY" in this file with your key.
Note that Secret.swift file has been added to the .gitignore file to avoid the file from getting added to the git repository.
### Add local images
A few images from Pexels have been added to the Images folder, and this folder has been added to .gitignore. The images are referenced in the localImagesInfo array in PexelsSupport.swift. You can add any local images as appropriate; these will be used if WiFi and mobile broadband connections are not available (a random image from one of these will be displayed).
Also, city_skyline.jpeg from the Images folder is used in the LaunchScreen.storyboard. You can download and use this image or any other image by referencing that file in the storyboard.

## License
This project is licensed under the terms of the MIT license.



