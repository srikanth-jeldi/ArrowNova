# Home Studio: fixed-view 2D room challenges

Packaged in the signed production AAB for 0.2.25 (27): mobile/ArrowNova-0.2.25-play.aab. Bundletool validation and signature verification passed; live ad IDs and all seven decor assets were verified. Physical-device testing remains pending.

## Available designs

- Three photographic room colour themes: warm oak, blush pink, soft blue. They share the same living-room architecture and camera. The themes cycle every three room challenges; this does not generate new architectural layouts.
- Seven categories: sofas, pillows, carpets, curtains, flower vases, framed pictures and floor lights.
- Four distinct art collections per category, 28 pieces total: Everyday Linen, Emerald Elegance, Rose Atelier and Coastal Blue. Each has different shapes/materials, not just runtime tinting.
- Seven Everyday pieces are free and owned in every room. Every room can be finished without ads.
- Each premium piece requires three earned rewarded-ad callbacks for that room only. Each ad is a separate voluntary tap. Cancellation and unavailable ads grant nothing. Credits persist after every earned reward and resume after restart.
- Matching and contrasting palette suggestions depend on the room colour. Suggestions never prevent other combinations. Previewing a piece in the room is free and does not change the saved design or grant ownership.
- Category-specific placement sockets keep perspective and layering consistent. No rotating camera or free-form furniture movement in this mode.
- Fill all seven categories, then Finish & save. The finished room becomes a read-only gallery entry. Next room starts empty with free items owned and fresh premium counters. Old finished rooms retain their premium art.

## Persistence and compatibility

The new `homeDecor2D` field stores the current level and each room's selected items, ad credits and completion flag. Existing puzzle, garden and legacy home fields are retained unchanged. Legacy 3D home layouts are retained in saved data but are not converted into the new fixed-slot studio or shown by its gallery. The Garden entry keeps permanent garden ownership and its existing ad flow; Home Decor opens the new studio.

## Artwork and size

Original assets were generated with the built-in image_gen tool, then encoded as WebP without resizing. Sprite alpha is retained. Individual sprite bounds are defined in the renderer; source atlases remain intact. Final assets live in `mobile/assets/art/decor/`. The seven WebP files total 1,073,626 bytes (about 1.02 MiB); this is asset size, not a measured APK increase. Exact prompts are saved in `docs/home-studio-art-prompts.json`.

Reference: https://play.google.com/store/apps/details?id=com.crowdstar.covetHome&hl=en_IN — room challenges and catalogue-style furniture selection informed the flow. No reference game artwork, brands or screens were copied.

## Validation

Model and widget tests cover free completion, three-ad unlocks, restart persistence, room-specific counters, retained gallery designs, unavailable/dismissed ads, double taps and finish/next navigation. Flutter-rendered phone previews and a three-theme comparison are in `design/previews/home-studio-*.png`. Live ads and physical-phone performance have not been tested for this change.

The regression run passed 101 tests and found one expected garden golden-image mismatch caused by the updated explanatory copy. After reviewing that image and updating its baseline (including the corrected garden-only collection count), the garden and new studio suites passed all six focused tests. Both preview rendering checks passed. The unchanged exhaustive dense-level catalogue sweep was excluded from the regression run.
