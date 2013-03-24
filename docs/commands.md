| Command                               | Action                                     |
|---------------------------------------|--------------------------------------------|
| play *track*                          | Queue this song.                           |
| play *artist*                         | Queue 10 tracks by this artist.            |
| play *album*                          | Queue this entire album.                   |
| play *something now*                  | Play this shit right now!                  |
| what                                  | Show what is playing, and what is queued.  |
| next                                  | Jump to the next song in the queue.        |
| undo                                  | Undo the last addition to the queue.       |
| clear                                 | Clear the queue.                           |
| pause                                 | Pause.                                     |
| unpause                               | Unpause.                                   |
| volume?                               | Get the current volume level.              |
| volume *0-100*                        | Set the volume.                            |

<br>
For example:

`play coldplay` plays the top 5 tracks by Coldplay.

`play nicki minaj starships` will play the (excellent) song Starships.

Mumbletune uses Spotify to find and play music. You can `play` a Spotify URL directly instead of searching, like

`play spotify:album:1HjSyGjmLNjRAKgT9t1cna`

<!-- Generate HTML with: $ pandoc -f markdown -->