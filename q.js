#!/usr/bin/env node
const { execSync } = require('child_process');
const fs = require('fs-extra');
const program = require('commander');

var cache_backup_path = "./.cache";
var java_options = "-Xmx=256m";

var launcherArgs = [];
// any args after -- should be passed directly to the launcher 
var passthroughIndex = process.argv.indexOf('--');
if (passthroughIndex >= 0)
{
    launcherArgs = process.argv.slice(passthroughIndex + 1);
    process.argv = process.argv.slice(0, passthroughIndex);
    console.log("launcherArgs", launcherArgs);
    console.log("process.argv", process.argv);
}

program
    .version('0.1.0')
    .description('Quick launch utility')
    .option('-p, --package',       'Packages the launcher for the current platform')
    .option('-P, --platform <platform>',  'Packages the launcher (all platforms)', process.platform)
    .option('-A, --arch <arch>',         'Use the 32bit launcher for all actions', process.arch)
    .option('-c, --clean',         'Clears the  launcher cache to simulate a fresh install')
    .option('-C, --clear-cache',  'Clears both launcher and backup caches')
    .option('-l, --launch',        'Runs the launcher with any passed flags')
    .option('-j, --javaoptions',   'Populates _JAVA_OPTIONS for this launch')
    .option('-h, --help',          'Passes --help')
    .option('-s, --steam',         'Passes --steam        (Implies    --attach, --noupdate)')
    .option('-a, --attach',        'Passes --attach')
    .option('-d, --detach',        'Passes --detach       (Overwrites --attach)')
    .option('-N, --noupdate',    'passes --noupdate')
    .option('-v, --debugging',     'Passes --noupdate --debugging')
    .option('-vv, --verbose',      'Passes --noupdate --debugging --verbose')
    .option('-D, --development', 'Passes --development')
    .option('-T, --capture',     'Passes --capture-game-log')
    .option('-t, --test',          'Runs the launcher with --debugging')
    .option('-tt, --test-verbose', 'Runs the launcher with --debugging --verbose')
    .option('-O, --dest <steam|vm>', 'Destination either steam or vm?')
    .parse(process.argv);

// Since we've overridden the standard help behaviour. Show help when no args are given
if (process.argv.length < 3)
    program.help();

if (program.package)
{
    console.log(`Packaging for ${program.platform} (${program.arch})`);
    const child = execSync(
        `node node_modules/gulp/bin/gulp.js package --platform ${program.package} --arch ${program.arch}`,
        { stdio: 'inherit' }
    );
}

if (program.dest === "steam")
{
    console.log(`Removing previous steam install`);
} 
if (program.dest === 'vm')
{
    console.log(`Removing previous VM builds`);
}
if (program.clearCache)
{
    console.log(`Clearing backup cache`);
    fs.removeSync(cache_backup_path);
}
if (program.clean)
{
    const platform = program.platform === 'all' ? '*' : program.platform;
    const arch = program.arch === 'all' ? '*' : program.arch;
    console.log(`Clearing launcher cache ${program.platform} (${program.arch})`);
    fs.removeSync(`./dist/starmade-launcher-${platform}-${arch}/.cache`);
}

if (program.launch)
{
    // Use current process plaltform and arch incase 'all' has been set in arguments
    const platform = program.platform === 'all' ? process.platform : program.platform;
    const arch = program.arch === 'all' ? process.arch : program.arch;

    launch_dir = `./dist/starmade-launcher-${platform}-${arch}`;
    if (program.dest === 'steam')
    {
        launch_dir = 'f:/Steam/SteamApps/common/StarMade'
    }
}