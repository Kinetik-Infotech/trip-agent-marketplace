# Hotel features

A fixed set of labels, scored for every hotel the traveller answers on, so the planner can see which features separate their yeses from their noes and rank new candidates on them. The matrix lives in the traveller's profile.

## Labels

Score each from the review site's details and reviews (for Tripadvisor: `hotel_details` with reviews and amenities). Take the room count from the hotel's own site or a booking site when the review site doesn't give it. Write "–" when no source says, never a guess.

| Label | Values |
|---|---|
| Rooms | the number, or: up to 15, 16 to 40, 41 to 100, over 100 |
| Adults only | yes, no |
| Setting | beachfront, near beach, cliff or hill with sea view, jungle or rice fields, countryside or hills, town or city |
| Design | up to two of: organic and handmade, white minimal, whitewash, heritage, classic luxury, sleek (glass and concrete), dated |
| Age | new (last 3 years), recently renovated, established, dated (reviews say so) |
| Atmosphere | up to two of: quiet retreat, romantic, sociable, family, party, business |
| Bar | a bar or beach club worth going to, an ordinary bar, none |
| Wellness | any of: spa, yoga, wellness programme, gym; or none |
| Pool | infinity or sea view, private pool villas, garden pool, ordinary pool, none |
| Rooms are | villas, suites, rooms |
| Service in reviews | personal and warm, polished and formal, patchy |
| Food in reviews | a highlight, fine, weak |
| Who stays | any of: couples, solo, families, groups, business |
| Owner | independent, small group, large chain |
| Price | per night, in the traveller's currency where a source gives it |
| Reviews | score and count, and the area ranking (#2 of 84 in Pecatu) |

## Using it

- **Score as you go.** Add a row to the profile's matrix for every hotel the traveller answers on: chosen, contender, liked from photos, lukewarm, or turned down, with a short plain reason.
- **Find the labels that separate.** A label counts when it is common among the hotels they chose and rare among the ones they turned down. Write the ones that separate, and the ones that don't, under the matrix as plain statements, without counts or examples. Update them as rows are added.
- **Weigh stays above looks.** A hotel liked from a photo tells you about looks. A hotel chosen for a stay tells you about everything else.
- **Rank candidates.** Score each candidate from the ranking search on the same labels, and propose first the one that matches most of the separating labels.
- **Never rule out on a label.** A label that separates is a preference, not a rule. Only the traveller's own words rule something out.
- **Say when the profile disagrees with itself**, in one line, once (for example: asked for sociable, but chose quiet retreats). Don't resolve it for them.
- **Check reviews against photos.** A hotel liked from photos whose reviews say patchy service, weak food or dated is flagged before it's proposed.
