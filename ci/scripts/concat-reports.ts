const { promises: fs } = require('fs');

async function getJson() {
  const admin = await fs.readFile('./ci/cucumber/admin-report.json', 'utf-8');
  const broker = await fs.readFile(
    './ci/cucumber/brokers-report.json',
    'utf-8'
  );
  const coverall = await fs.readFile(
    './ci/cucumber/coverall-report.json',
    'utf-8'
  );
  const employee = await fs.readFile(
    './ci/cucumber/employee-report.json',
    'utf-8'
  );
  const employers = await fs.readFile(
    './ci/cucumber/employers-report.json',
    'utf-8'
  );
  const generalAgencies = await fs.readFile(
    './ci/cucumber/general-agencies-report.json',
    'utf-8'
  );
  const groupSelection = await fs.readFile(
    './ci/cucumber/group-selection-report.json',
    'utf-8'
  );
  const hbx = await fs.readFile('./ci/cucumber/hbx-report.json', 'utf-8');
  const hbxAdmin = await fs.readFile(
    './ci/cucumber/hbx-admin-report.json',
    'utf-8'
  );
  const insured = await fs.readFile(
    './ci/cucumber/insured-report.json',
    'utf-8'
  );
  const integration = await fs.readFile(
    './ci/cucumber/integration-report.json',
    'utf-8'
  );
  const permissions = await fs.readFile(
    './ci/cucumber/permissions-report.json',
    'utf-8'
  );
  const planShopping = await fs.readFile(
    './ci/cucumber/plan-shopping-report.json',
    'utf-8'
  );

  const jsonFiles = [
    admin,
    broker,
    coverall,
    employee,
    employers,
    generalAgencies,
    groupSelection,
    hbxAdmin,
    hbx,
    insured,
    integration,
    permissions,
    planShopping,
  ];

  const allReports = jsonFiles.reduce((allReports, report) => {
    const parsed = JSON.parse(report);

    return [...allReports, ...parsed];
  }, []);

  const jsonList = JSON.stringify(allReports);

  await fs.writeFile('./ci/cucumber/cucumber-report.json', jsonList);
}

getJson();
