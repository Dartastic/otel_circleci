// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_circleci_suppression.dart';

const _tracerName = 'dartastic_otel_libs_circleci';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Wraps a CircleCI v2 API call (project.trigger, pipeline.get,
/// workflow.cancel, etc.) in a CLIENT span.
Future<T> tracedCircleci<T>({
  required String resource,
  required String action,
  required Future<T> Function() invoke,
  String? projectSlug,
  String? pipelineId,
  String? workflowId,
  String? jobNumber,
}) async {
  if (circleciInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'cicd.system': 'circleci',
    'circleci.resource': resource,
    'circleci.action': action,
    'circleci.operation': '$resource.$action',
  };
  if (projectSlug != null) m['circleci.project.slug'] = projectSlug;
  if (pipelineId != null) m['circleci.pipeline.id'] = pipelineId;
  if (workflowId != null) m['circleci.workflow.id'] = workflowId;
  if (jobNumber != null) m['circleci.job.number'] = jobNumber;

  final span = _tracer().startSpan(
    'circleci $resource.$action',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
