# Connectors

The planner uses the traveller's own travel connectors, added in their Claude account from the connector directory. It never books or pays: searches return links to the provider.

| Connector | Used for |
|---|---|
| Kiwi.com | Flights, with stops, layovers and stopovers |
| Tripadvisor | Reviews, review counts, ranking (search sorted by popularity), photos. Prices come in US dollars only, before taxes: convert them with scripts/fx.py |
| Brek | Hotel prices for exact dates, in pounds |
| Civitatis, Veltra | Activities and tours |
| AccuWeather | Weather |

Tripadvisor needs `mcpServerVersion: {"version": "V2026_0327"}` and `requestContext: {"clientType": "DESKTOP"}` on each call.

If a connector the planner needs isn't connected, say which one and what it is for, in one line, and carry on with the others.
