// rdf_owl.dart — RDF/OWL source adapter for pack_builder.
//
// Fetches ontology terms from the EMBL-EBI Ontology Lookup Service (OLS),
// which serves the same RDF/OWL data as clean JSON, and emits RawCards of the
// form "X is part of Y" (front = term label, back = its part_of parent label).
//
// Why OLS and not the raw .owl: the full UBERON ontology is a 96MB RDF/XML
// file covering the whole metazoan tree. Parsing that wholesale in Dart is
// fragile and memory-heavy, and a skeletal pack only needs a bounded set of
// terms. OLS is the ontology's official REST endpoint and returns the same
// asserted relationships (subClassOf, part_of) as JSON. The adapter is generic:
// any IRI (or comma-separated list of IRIs) works, so it can pull any OBO/OWL
// ontology OLS hosts (UBERON, FMA, CL, …).
//
// License: the adapter itself is generic code. The DATA it fetches carries the
// source ontology's license — UBERON is CC-BY-3.0 (attribution + indicate
// changes + no-added-restrictions; NOT share-alike, so a derived pack may be
// released under CC0 with attribution). The pack builder's --license /
// --source-name / --source-url flags carry that at deck level.
//
//   dart run tools/pack_builder.dart \
//     --out skeleton/packs/skeleton.json \
//     --deck us-skeleton \
//     --license CC-BY-3.0 \
//     --source-name "UBERON anatomy ontology (skeletal terms)" \
//     --source-url "https://www.ebi.ac.uk/ols4/ontologies/uberon" \
//     --source "rdf-owl:http://purl.obolibrary.org/obo/UBERON_0000976,http://purl.obolibrary.org/obo/UBERON_0006849"
//
// The source spec is `rdf-owl:<iri>[,<iri>...]` — each IRI is a leaf term whose
// label + part_of parents are fetched. Multiple --source rdf-owl:... merge +
// dedupe like any source.

import 'dart:convert';
import 'dart:io';

import 'raw_cards.dart';

/// OLS API base. The ontology name is derived from the IRI's prefix (UBERON_…).
const _olsBase = 'https://www.ebi.ac.uk/ols4/api/ontologies';

/// The `part_of` relation IRI (BFO:0000050), used to build "X is part of Y".
const _partOfIri = 'http://purl.obolibrary.org/obo/BFO_0000050';

/// Parse an RDF/OWL source: [location] is a comma-separated list of term IRIs.
/// Returns "X is part of Y" cards (front = term label, back = part_of parent).
Future<List<RawCard>> rdfOwlParse(String location) async {
  final roots = location
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (roots.isEmpty) return const [];

  final cards = <RawCard>[];
  final seen = <String>{};

  for (final root in roots) {
    // Fetch the term itself (label) + its part_of parents. Each root is a leaf
    // term to emit "X is part of Y" cards for — not a subtree to walk (walking
    // the whole skeleton subtree is thousands of slow OLS calls).
    final term = await _olsTerm(root);
    if (term == null) continue;
    final id = term['obo_id'] as String? ?? '';
    final label = term['label'] as String? ?? '';
    if (id.isEmpty || label.isEmpty) continue;
    if (seen.contains(id)) continue;
    seen.add(id);

    // part_of parents -> "X is part of Y" cards.
    final parents = await _partOfParents(term['iri'] as String);
    if (parents.isEmpty) continue;
    for (final parent in parents) {
      final parentLabel = parent['label'] as String? ?? '';
      if (parentLabel.isEmpty) continue;
      cards.add(
        RawCard(
          id: id,
          front: label,
          back: parentLabel,
          domain: 'anatomy',
          scope: 'skeleton',
          source: term['iri'] as String? ?? id,
          bokReferences: [id],
        ),
      );
    }
  }
  return cards;
}

/// Fetch a single term object by IRI (label, obo_id, iri).
Future<Map<String, dynamic>?> _olsTerm(String iri) async {
  final url = '$_olsBase/uberon/terms/${_doubleEncode(iri)}';
  final resp = await _httpJson(url);
  if (resp == null) return null;
  // Single-term fetch returns the term object directly (no _embedded wrapper).
  return resp['label'] is String ? resp : null;
}

/// Fetch the `part_of` parents of [iri] (BFO:0000050 relation).
Future<List<Map<String, dynamic>>> _partOfParents(String iri) async {
  return _olsGet(iri, _partOfIri);
}

/// GET a relation/term path under the UBERON ontology, paginated, returning the
/// list of term objects. [iri] and [relation] are each double-URL-encoded as a
/// single path segment (OLS requires the full IRI encoded twice, not split on
/// its internal slashes).
Future<List<Map<String, dynamic>>> _olsGet(
  String iri,
  String relation,
) async {
  final all = <Map<String, dynamic>>[];
  var page = 0;
  while (true) {
    final url =
        '$_olsBase/uberon/terms/${_doubleEncode(iri)}/${_doubleEncode(relation)}'
        '?size=100&page=$page';
    final resp = await _httpJson(url);
    if (resp == null) break;
    final embedded = resp['_embedded'];
    final terms = (embedded is Map && embedded['terms'] is List)
        ? (embedded['terms'] as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    all.addAll(terms);
    final pageInfo = resp['page'];
    final totalPages = (pageInfo is Map ? pageInfo['totalPages'] : 0) as int? ?? 0;
    if (page >= totalPages - 1) break;
    page++;
  }
  return all;
}

/// Double URL-encode a path segment (OLS requires the IRI to be encoded twice).
String _doubleEncode(String segment) {
  final once = Uri.encodeComponent(segment);
  return Uri.encodeComponent(once);
}

/// GET a JSON object from [url], retrying on transient failures (OLS
/// rate-limits and times out under load). Returns null after retries exhausted.
Future<Map<String, dynamic>?> _httpJson(String url) async {
  for (var attempt = 0; attempt < 4; attempt++) {
    final client = HttpClient();
    try {
      final req = await client.getUrl(Uri.parse(url));
      req.headers.set('Accept', 'application/json');
      final resp = await req.close();
      if (resp.statusCode != 200) return null;
      final body = await resp.transform(utf8.decoder).join();
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      // transient — back off and retry
    } finally {
      client.close();
    }
    await Future<void>.delayed(Duration(milliseconds: 500 * (attempt + 1)));
  }
  return null;
}
