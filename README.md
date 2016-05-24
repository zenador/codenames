## Description

Unofficial online clone of the board game 'Codenames' (designed by Vlaada Chvátil and published by Czech Games Edition) with the following features:
- Replace any word you want if you don't like the generated grid
- Load custom word lists
- Customise grid size and number of cards of each colour
- Connect a game room to a Telegram chat group through a bot to get notified when someone has taken a turn and to make guesses through chat (useful to play it as turn-based instead of real-time, especially when it gets draggy playing with people who like to take their time to think. For now, setup has to be done through the web app first, though this may change later)
- Hide the words and just use it with physical cards as a colour grid generator
- Layout responsive to different screens (desktop, mobile, etc)

## Link

- Try it out here: [Codenames](http://codenamesgame.herokuapp.com)
- Optional companion Telegram bot: [@CodenamesBot](http://telegram.me/CodenamesBot)

## Instructions

1. Edit config/settings-example.json to put in your own tokens, URLs, etc.
2. From your terminal, go to this directory, then run `meteor --settings config/settings-example.json`
