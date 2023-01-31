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

async function downloadArtifacts(jobsPromise) {
    console.log("Started downloadArtifact-function")
    const jobs = await jobsPromise;
    // console.log("Waited for jobs to be resolved")
    // console.log(jobs)
    for (let jobIdx = 0; jobIdx < jobs.length; jobIdx++) {
        if (jobs[jobIdx].artifacts.some(element => element.file_type == "archive")) {
            downloadSingleArtifact(jobs[jobIdx]);
        } else {
            console.log(`Job ${jobs[jobIdx].id} does not seem to exhibit an artifact`);
        }
    }      
}


async function downloadSingleArtifact(job) {
    const fs = require('fs');
    const {Readable} = require('stream');
    const {finished} = require('stream/promises');

    const getArtifact = singleJob => {
        for (let idx = 0; idx < singleJob.artifacts.length; idx++){
            if (singleJob.artifacts[idx].file_type == "archive") {
                return singleJob.artifacts[idx]
            }
        }
        throw `No artifact file found in job ${singleJob.id}`;
    }
    const artifact = getArtifact(job);
    const fileName = artifact.filename
    const jobName = job.name;
    const jobID = job.id;
    const fileURL = `https://${process.env.GITLAB_HOSTNAME}/api/v4/projects/${process.env.GITLAB_PROJECT_ID}/jobs/${jobID}/artifacts`;
    console.log(`Job ${job.id} has an artifact with name ${fileName}`);
    const fileStream = fs.createWriteStream(`${jobName}.${artifact.file_format}`);
    const {body} = await fetch(fileURL, {
        // headers: {
        //     'PRIVATE-TOKEN': process.env.GITLAB_TOKEN,
        // },
        });
    await finished(Readable.fromWeb(body).pipe(fileStream));
    console.log(`Downloaded artifact from job ${jobName}`)
}

setEnvironmentVariables();
const jobs = getListjobs();
downloadArtifacts(jobs);
// console.log(`Jobs that have been found: ${getListjobs()}`);
