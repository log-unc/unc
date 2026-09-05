export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === "/script.lua") {
      const asset = await env.ASSETS.fetch(new URL("/script.lua", request.url));

      if (!asset.ok) {
        return new Response("-- script is unavailable\n", {
          status: 404,
          headers: { "content-type": "text/plain; charset=utf-8" }
        });
      }

      return new Response(asset.body, {
        status: 200,
        headers: {
          "content-type": "text/plain; charset=utf-8",
          "cache-control": "public, max-age=300",
          "access-control-allow-origin": "*"
        }
      });
    }

    if (url.pathname.startsWith("/data/")) {
      const asset = await env.ASSETS.fetch(request);

      if (!asset.ok) {
        return new Response(JSON.stringify({ error: "not found" }), {
          status: 404,
          headers: { "content-type": "application/json; charset=utf-8" }
        });
      }

      const headers = new Headers(asset.headers);

      headers.set("content-type", "application/json; charset=utf-8");
      headers.set("cache-control", "public, max-age=60");
      headers.set("access-control-allow-origin", "*");

      return new Response(asset.body, { status: 200, headers });
    }

    return env.ASSETS.fetch(request);
  }
};
