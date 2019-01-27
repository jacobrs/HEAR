## HEAR - Generating Subtitles for Life

!-- todo add logo -->

### Introduction
HEAR is an iOS application that listens to a speaker using a phone camera and microphone, then adds subtitles under them to allow the hearing impaired to understand what they are saying. The application works best in quiet areas with minimal background noise. Subtitles track human faces and attempt to follow them in the augmented reality scene.

### Inspiration
Inspired by a recent conference talk on accessibility as well as family members that are hearing impaired, we wanted to create a hack that targeted pain points that individuals with hard of hearing deal with, every day.

### Technologies<br><br>

<div style="display:inline-block">
  <img height="64px" src="https://developer.apple.com/assets/elements/icons/arkit/arkit-64x64_2x.png"/>
  <img height="64px" src="https://developer.apple.com/assets/elements/icons/core-ml/core-ml-128x128_2x.png"/>
  <img height="64px" src="https://developer.apple.com/assets/elements/icons/sirikit/sirikit-96x96_2x.png">
  <img height="64px" src="https://developer.apple.com/assets/elements/icons/spritekit/spritekit-128x128_2x.png">
</div>

#### ARKit 2
The ARKit 2 was used to capture objects in a 3D scene and attach subtitle nodes to them allowing the subtitles to follow speakers. Subtitle text size is dictated based off distance which would not be possible without ARKit.

#### CoreML 2
CoreML2 was mostly used for its computer vision application. HEAR uses facial recognition to detect potential speakers and to position subtitles in the right position. This is achieved efficiently by utilizing the Vision API.

#### SiriKit
Speech to text is the most important feature of HEAR and for that reason, the SiriKit was chosen to transcribe speech from speakers to subtitles. Having Siri perform some computations and natural language processing locally helps speedup the transcription which leads to a better user experience.

#### SpriteKit
HEAR uses SpriteKit to overlay the subtitles in the 3D rendered by ARKit. SpriteKit also allows text customization to make the text clearer and more legible on varying backgrounds.

### Demo
Simple scenario where a someone might be lecturing.

### Future Plans
The HEAR team has many ambitious plans for the application some of which include:
* Simultaneous speakers and subtitles
* More accurate speaker tracking
* Higher accuracy in noisy environments
* Syncing of conversations to cloud for later review
* Integration into augmented reality lenses
* Real time translation of subtitles

### Authors
Benjamin Barault, Francesco Valela, Jacob Gagné, Tobi Décary-Larocque

<br><br>


