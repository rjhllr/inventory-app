## Inventory App
I want to build a Flutter App for the basic stock taking that you have to do at the start of the year (in German: Inventur). I want this app to be pretty simple while easily integrating with other workflows. I want to offer some commercial upgrades (like pulling product data from EAN APIs for more complete files). 
## Requirements
It is required for this app to support iOS and Android. We just need to be publishable, we don't need a real native design for each platform really.
### Pluggable Data Architecture
PLease keep the data architecture pluggable: use a pattern where all data changes are made in a way that we can easily plug an external JSON rest API. Use a database that supports concepts like joins and such (maybe Turso?) and keep all of that code hidden away nicely, to be easily replaced by API later. Implement loading or background processing for all actions that may be networked. Ensure scanning can work through minutes of offline use!
### Data Export
Data Export should be supported to e.g. zip files. 
### Data Model
For our scanning data model (which is basically the only output this app generates) please track the product identifier (whatever is scanned, we can't know) and the count. THe user has the ability to add prompt columns (things that are asked when doing inventory) which we'll also add to the data output.
### Screen-by-Screen
#### Home Screen
Show the following buttons/info cards in order:
- Start Stockkeeping (to "Scanning Screen")
- Stockkeeping Settings
- Product Database
- Scan Results + <Count of Scans>
Also support a callout for Upgrades (like AI Scanning).
#### Scanning Screen
The scanning screen should feature a horizontally split view with a movable divider line. The top view should be the scanner with a simple readiness toggle showing whether it scans or not (easy pause option for when you need to do something else). The scanner should use the devices camera and continuous QR scanning. Scans should be confirmed by a small beep. Depending on the users settings, the count (or other prompt columns) should be asked for after the item is scanned. 
The other half of the screen will show the running scanning results, with new lines showing with a fading background so you know that you just scanned them. Re-scanning an article will increase its quantity, but not re-ask prompt questions. 
#### Stockkeeping Settings
This screen allows the user to configure how their stockkeeping is done in detail.
##### Prompt Quantity
Toggle that enables quantity prompting (= asking the scanning user after their scan to enter a quantity)
##### Additional Prompt Questions
This segment allows the user to add prompt questions that need to be entered afterwards. We should support different input types (take photo, number input, text input). It should be selectable whether a question (except for quantity, makes no sense there) is asked only once (e.g. to collect product data) or for every scan (e.g. to ensure we record expiry dates).
Data will automatically be saved to the product database and the field edit UI is reusable between them. Fields added to product DB or as a prompt question should automatically end up in the other one. For prompt questions its optional, since we'd have different group-by-columns for things like expiry date. Thus, user-selectable whether additional prompt question saves to scan result or product DB. Clearly explain the difference between the two and give examples in the UI.
#### Product Database
Part of the mission of this app is the ability to build up your own product database continually. Thus, it would be really helpful if scans automatically started collecting product data. The product database thus should know every identifier we ever saw across all scans and allow the user to add data to it (adding new fields, columns…)
Product detail screen should show number of scans, last seen, and (potential) additional information added to either the scan result or its product database entry. 
The product detail screen (clicking from the list view) should automatically show a scan history as well. 
#### Scan Result Screens
The scan results screen is a different view onto our centralized database. It should show all scan operations, alongside any product information (like name or such) may present in DB, ordered by date (so the user can review/change their latest scans).

# Commercial Direction
- Add AI interpretation of scanned images (or new AI scanner mode)
- Call EAN/GTIN DBs to fill product DB
- Different export formats (paid)
- Develop it into a small ERP / business system