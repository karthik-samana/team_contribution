-- Run this in Supabase SQL Editor to switch the live event to Shiva's farewell.

UPDATE settings
SET
  event_name = 'Shiva''s Farewell Contribution',
  message = 'Hi Team,

As Shiva Prasad is moving to a different team, let''s take some time to get together and wish him all the very best for his next journey.

Shiva has always been one of those people who steps forward when it comes to team activities, whether it''s planning outings, coordinating things, bringing people together, or simply making everyone feel comfortable with his friendly nature.

Let''s catch up, share a few memories, and give him a warm send-off!

Monday, 26 October | 3:00-3:30 PM

Host: Samana

See you all there!

Thanks,
Samana',
  is_active = true,
  updated_at = NOW()
WHERE id = 1;
