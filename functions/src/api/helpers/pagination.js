/**
 * Parser pagination query string untuk Express routes.
 *
 * Query params:
 *   ?limit=20          (1-100, default opts.defaultLimit)
 *   ?cursor=<lastDocId>  (opsional — pass last doc id dari halaman sebelumnya)
 *
 * Return { limit, cursor }.
 */
function parsePagination(query, opts = {}) {
  const defaultLimit = opts.defaultLimit || 20;
  const maxLimit = opts.maxLimit || 100;

  let limit = parseInt(query?.limit, 10);
  if (!Number.isFinite(limit) || limit < 1) limit = defaultLimit;
  if (limit > maxLimit) limit = maxLimit;

  const cursor = typeof query?.cursor === "string" && query.cursor.length > 0 ?
      query.cursor :
      null;

  return {limit, cursor};
}

module.exports = {parsePagination};
