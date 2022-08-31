export const buildChartsData = (selectedTestRunFromDashboard) => {
  const classesAndBenchmarks = {};
  selectedTestRunFromDashboard?.statistics?.forEach((testRun, index) => {
    // Benchmark example string: "benchmark": "benchmark.ListBenchmark.benchmarkArrayList"
    var benchmarkCassAndMethod = testRun.benchmark.split('.');
    var benchmarkClass = benchmarkCassAndMethod[1] + '-' + testRun.mode;
    var benchmarkMethod = benchmarkCassAndMethod[2];
    var benchmarkData = {
      jobId: selectedTestRunFromDashboard?.id,
      benchmarkClass: benchmarkClass,
      benchmarkMethod: benchmarkMethod,
      benchmarkScore: testRun.primaryMetric.score,
      benchmarkError: testRun.primaryMetric.scoreError,
      mode: testRun.mode,
      json: testRun,
    };
    classesAndBenchmarks[benchmarkClass] ??= [];
    classesAndBenchmarks[benchmarkClass]?.push(benchmarkData);
  });

  var allClassesAndBenchmarks = [];

  Object.entries(classesAndBenchmarks).forEach(([key, value]) => {
    const uniqueIds = new Set();
    const unique = value.filter((element) => {
      const isDuplicate = uniqueIds.has(element.benchmarkMethod);
      uniqueIds.add(element.benchmarkMethod);
      if (!isDuplicate) {
        return true;
      }
      return false;
    });
    allClassesAndBenchmarks[key] = unique;
  });

  var sortedByClassNameClassesAndBenchmarks = Object.entries(allClassesAndBenchmarks).sort();
  return sortedByClassNameClassesAndBenchmarks;
};

export const buildIndividualJsonResults = (benchmarks) => {
  const jobId = benchmarks[0].jobId;
  const className = benchmarks[0].benchmarkClass;
  const jsonResults = benchmarks.map((benchmark) => benchmark.json);

  return {
    jobId,
    className,
    jsonResults,
  };
};

export const buildJsonResults = (benchmarks) => {
  const jobId = benchmarks[0][1][0].jobId;
  const jsonResults = benchmarks.map((benchmark) => {
    return benchmark[1].map((jsonRes) => jsonRes.json);
  });

  return {
    jobId,
    className: '',
    jsonResults,
  };
};

export const downloadJSON = (jsonBnechmark, jobId, jsonData) => {
  const fileData = JSON.stringify(jsonData);
  const blob = new Blob([fileData], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.download = jsonBnechmark ? `${jsonBnechmark}-${jobId}.json` : `Test-run-${jobId}.json`;
  link.href = url;
  link.click();
  return link;
};
