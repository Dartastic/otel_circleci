// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_circleci/otel_circleci.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_circleci-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('project.trigger records CLIENT span', () async {
    await tracedCircleci<String>(
      resource: 'project',
      action: 'trigger',
      projectSlug: 'github/acme/app',
      pipelineId: 'p-1',
      invoke: () async => 'ok',
    );
    final a = attrsOf(spans.findSpanByName('circleci project.trigger')!);
    expect(a['cicd.system'], 'circleci');
    expect(a['circleci.project.slug'], 'github/acme/app');
    expect(a['circleci.pipeline.id'], 'p-1');
  });

  test('suppression skips spans', () async {
    await runWithoutCircleciInstrumentationAsync(() async {
      await tracedCircleci<String>(
        resource: 'project',
        action: 'trigger',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('circleci '), isEmpty);
  });
}
