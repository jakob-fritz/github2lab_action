let process = {
    env : {},
}

function setEnvironmentVariables() {
    process.env.GITLAB_HOSTNAME = "codebase.helmholtz.cloud";
    process.env.GITLAB_PROJECT_ID = "6234";
    process.env.GITHUB_SHA = "9e05b5a3320eaa72181f3da00d923a5067e7b6aa";
}


async function getListjobs() {
    // Determine Pipeline-URL
    const pipelineURL = `https://${process.env.GITLAB_HOSTNAME}/api/v4/projects/${process.env.GITLAB_PROJECT_ID}/repository/commits/${process.env.GITHUB_SHA}`;
    console.log(`URL is ${pipelineURL}`);
    const pipelineID = await fetch(pipelineURL, {
        // headers: {
        //     'PRIVATE-TOKEN': process.env.GITLAB_TOKEN,
        // },
        })
        .then(response => response.json())
        .then(pipeline => pipeline.last_pipeline.id);
    console.log(`Pipeline-ID is ${pipelineID}`);
    
    // Get list of jobs in this pipeline
    jobsURL = `https://${process.env.GITLAB_HOSTNAME}/api/v4/projects/${process.env.GITLAB_PROJECT_ID}/pipelines/${pipelineID}/jobs`;
    console.log(`URL for jobs is ${jobsURL}`);
    const jobsObj = await fetch(jobsURL)
        .then(response => response.json());
    console.log(`Jobs are of type ${typeof jobsObj}`);

    return jobsObj;
}


setEnvironmentVariables();
const jobs = getListjobs();
