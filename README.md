
## OAuth Ruby Sample

This is an OAuth sample that uses a Sinatra server.`

We use shell variables to set

`export CLIENT_ID="817b4273628c415cbbfd657ab7224582"`

`export CLIENT_SECRET="ENpSjSRTTaWfK5YB4NE1TThwEkIeUg9oNd2fdMnKIQ"`

`export SERVER_URL="http://localhost:4567"`

To start the app

`foreman start`

If wanting to test using the OAuth 2.0 `password` wofklow (as opposeed to the `authorization_code` flow), then please also define these variables:

`export FD_USERNAME="user@company.com"`

`export FD_PASSWORD="t0pS3cr3t"`