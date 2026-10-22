# Sources, by stage

What each kind of connected system can give the round-out pass. Connectors are read, never written. Where a kind of source is absent, the stage asks the user or leaves the gap for `audit-the-map`.

| Source | Stage 1 tools | Stage 2 data model | Stage 3 assets | Stage 4 team | Stage 5 people |
|---|---|---|---|---|---|
| The workspace itself (tools, teams, roles, people, steps, the onboarding changelog entry) | what exists, what steps name | entities that exist | assets that exist | roles that exist, roles steps name | people that exist |
| A CRM (Attio, HubSpot, Salesforce) | the tool, its seats | objects and attribute definitions, live | lists, views, sequences, dashboards | the team that owns it | users of the CRM |
| A work-management tool (Monday.com, ClickUp, Asana) | the tool | boards and their columns, live | boards, forms, dashboards | teams as the tool shows them | members |
| An automation platform (Zapier, Make, n8n) | the tool | nothing | workflows and Zaps, with status | nothing | nothing |
| Billing and finance (Stripe, QuickBooks) | the tool, its plan | customers, invoices, products, live | reports | nothing | nothing |
| Support (Intercom, Featurebase) | the tool | contacts, conversations, articles | help articles, forms | nothing | teammates |
| Google Workspace | the tool, its seats | nothing | documents, sheets, slides, folders | org units as a hint for teams | the directory: name, email, title, manager |
| Slack | the tool, its plan | nothing | channels, canvases | nothing | users: name, email, title |
| A subscription or invoice export | tools and their costs | nothing | nothing | nothing | nothing |
| An org chart (file, image, description) | nothing | nothing | nothing | teams, roles, reporting lines | names in boxes, to be mapped to roles |
| A CSV of people | nothing | nothing | nothing | titles as role hints | name, email, title, team, manager |
| LinkedIn (company page, people search) | nothing | nothing | nothing | titles as role hints | a recommendation list: name and public title, confirmed name by name |
| The user | everything else | everything else | URLs for what no connector can see | rates, reporting lines, what each role owns | roles for named people, tool access |

Rules that apply to every row:

- Read only. Nothing is written to a source system.
- A cost, a rate, a URL or a role that no source states is asked for, never invented.
- A source's names are matched to the canvas by name before anything is proposed; a near-match ("HubSpot CRM" versus "HubSpot") is shown as a match to confirm, not as an Add.
- LinkedIn gives public titles only, as a recommendation the user confirms person by person. Nothing from it is pushed on its own.
- The onboarding changelog entry, where present, is read first: it says what Nova created and from which inputs.
