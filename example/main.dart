// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_circleci/otel_circleci.dart';

/// Traces CircleCI v2 calls with OpenTelemetry.
///
/// `otel_circleci` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each CircleCI v2 call in
/// [tracedCircleci]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'circleci-example');

  // Wraps a CircleCI v2 API call (project.trigger, pipeline.get, workflow.cancel, etc.) in a CLIENT span.
  final circleciId = await tracedCircleci<String>(
    resource: 'Order',
    action: 'example',
    projectSlug: 'example',
    pipelineId: 'pipeline_8f3a2c',
    workflowId: 'workflow_8f3a2c',
    jobNumber: 'example',
    invoke: () async {
      // Make the CircleCI v2 call here, then report what it returned.
      return 'circleci_8f3a2c';
    },
  );
  OTelLog.info('tracedCircleci returned $circleciId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutCircleciInstrumentationAsync.
  await runWithoutCircleciInstrumentationAsync(
    () => tracedCircleci<String>(
      resource: 'Order',
      action: 'example',
      projectSlug: 'example',
      pipelineId: 'pipeline_8f3a2c',
      workflowId: 'workflow_8f3a2c',
      jobNumber: 'example',
      invoke: () async {
        return 'circleci_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
