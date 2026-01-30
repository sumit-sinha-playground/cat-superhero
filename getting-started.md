We've added a basic level (level_example). With a cat that can run and jump, a background image, a floor and some platforms (StaticBody2D + CollisionShape2D) that the cat can jump on to.

The example level is very hard coded. Hopefully we can generate the different platforms in code, so that it’s less manual / faster and so that we can randomise it a bit.

You can run this level by selecting it and then clicking run current scene.

[how to run](./getting-started.png)

Main tasks:
* [Maryem] Create tree level - there will be a central tree trunk (that the cat can't collide with). The cat jumps from branch to branch until it saves the person at the top of the tree. Branches could break to make it more difficult.
* [David] Create building level - the cat will jump from windowsill to windowsill on tall skyscrapers. Some windowsills will become unavailable (e.g. if someone opens the window). There could be pipes / ladders between buildings (these could break too). The cat should try and save a human stuck at the top of a tall building.
* [Sumit] Create suburb level - the cat will explore a street, dodging manholes, dogs, people. Until they find the baby at the end.

Tree / building levels will be very similar to doodle jump https://www.youtube.com/watch?v=QVfkpZGOGBY

I think we can just use coloured rectangles for now and generate nicer assets later. In case it’s helpful, here are the prompts I was using to generate some of the assets:
* "Generate a pixel-art house looking at the house side on. We should be able to see a sitting room on the left hand side of the image with a sofa and a cat bed beside a table with the cat phone on it. There should be the outside wall of the house in the middle of the image. Outside the wall, on the right side of the image, there should be a garden with a fence and a cardboard box."
* "A pixel-art sprite sheet, space 6 frames evenly in a row. A cat on a white background. The row of frames should animate a cat standing still and looking around."

Future ideas:
* Fix cat jump whilst running
* Fix cat animations
* Menus - way to select different levels and transition after levels
* Create an intro video
* Add audio
* Multiplayer - multiple cats and then it's a race to the end? Experiment with controllers
* Add more levels
