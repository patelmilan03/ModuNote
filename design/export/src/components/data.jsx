// Shared seed data for the ModuNote mockups

const MN_NOTES = [
  { id: 'n1', pinned: true, title: 'Hook ideas for the Tokyo vlog', preview: 'Open on shinjuku crossing at night — then cut to the hotel window rain-soaked…', time: '2h ago', tags: ['youtube', 'videography', 'tokyo'] },
  { id: 'n2', pinned: true, title: 'Gear list — ND filters', preview: '3-stop for overcast, 6-stop for handheld daylight, variable for b-roll runs', time: 'Yesterday', tags: ['gear', 'videography'] },
  { id: 'n3', pinned: false, title: 'Reel script: "things I stopped buying"', preview: 'Cold open w/ empty shopping cart reveal. 27s total. Caption over voiceover.', time: '3d ago', tags: ['instagram', 'scripts'] },
  { id: 'n4', pinned: false, title: 'ADHD-proof editing workflow', preview: 'Batch the rough cut. Walk away 20 min. Return w/ fresh ears for audio pass.', time: '4d ago', tags: ['adhd', 'editing'] },
  { id: 'n5', pinned: false, title: 'Food content — ramen tasting series', preview: 'One shop per episode. 60s cap. B-roll: broth steam, noodle pull, chopsticks.', time: 'Mon', tags: ['food', 'instagram'] },
  { id: 'n6', pinned: false, title: 'Sponsorship one-liner', preview: 'Honest, specific, under 8 seconds. Never front-load the pitch.', time: 'Mar 28', tags: ['business'] },
];

const MN_TAGS = [
  { name: 'youtube', count: 24 },
  { name: 'videography', count: 18 },
  { name: 'instagram', count: 16 },
  { name: 'scripts', count: 12 },
  { name: 'editing', count: 11 },
  { name: 'food', count: 9 },
  { name: 'adhd', count: 7 },
  { name: 'gear', count: 6 },
  { name: 'tokyo', count: 4 },
  { name: 'business', count: 3 },
];

Object.assign(window, { MN_NOTES, MN_TAGS });
