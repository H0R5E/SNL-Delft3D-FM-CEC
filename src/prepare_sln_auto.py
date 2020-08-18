
import os
import glob
import sys
import shutil
import subprocess
import itertools
from contextlib import suppress

if sys.version_info < (3, 0, 0):
    # To avoid problems with encoding:
    # - Use codecs.open instead of open (Python 2.x only)
    # - open files with encoding='utf-8' (Both Python 2.x and 3.x)
    # - Do not use str(line) on lines read from file
    from codecs import open as open
    import _winreg as winreg
else:
    import winreg


# toolsversion specifies the vs toolsversion number
toolsversion = {}
toolsversion[2010] = "4.0"
toolsversion[2012] = "4.0"
toolsversion[2013] = "12.0"
toolsversion[2014] = "12.0"
toolsversion[2015] = "14.0"
toolsversion[2016] = "14.0"
toolsversion[2017] = "14.0"
toolsversion[2019] = "14.0"

# netcodes defines the .NET frameworks available
netcodes = [
    378389,
    378675,
    379893,
    393295,
    394254,
    394802,
    460798,
    461308,
    461808,
    528040,
]
netversions = [
    "4.5",
    "4.5.1",
    "4.5.2",
    "4.6",
    "4.6.1",
    "4.6.2",
    "4.7",
    "4.7.1",
    "4.7.2",
    "net48",
]


def subkeys(path, hkey=winreg.HKEY_LOCAL_MACHINE, flags=0):
    with suppress(WindowsError), \
         winreg.OpenKey(hkey, path, 0, winreg.KEY_READ|flags) as k:
        for i in itertools.count():
            yield winreg.EnumKey(k, i)


def get_highest_xe_version():
    
    key = "SOFTWARE\Wow6432Node\Intel\Products\Composer XE"
    versions = []
    
    for subkey in subkeys(key):
        REG_PATH = key + "\\" + subkey
        registry_key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE,
                                      REG_PATH,
                                      0,
                                      winreg.KEY_READ)
        value, regtype = winreg.QueryValueEx(registry_key, "MajorVersion")
        versions.append(value)
    
    if not versions:
        raise ValueError("Parallel Studio XE not found")
    
    return max(versions)


def get_highest_compiler_version():
    
    key = "SOFTWARE\Wow6432Node\Intel\Products\Compilers and Libraries"
    versions = []
    
    for subkey in subkeys(key):
        REG_PATH = key + "\\" + subkey
        registry_key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE,
                                      REG_PATH,
                                      0,
                                      winreg.KEY_READ)
        majorvalue, regtype = winreg.QueryValueEx(registry_key, "MajorVersion")
        minorvalue, regtype = winreg.QueryValueEx(registry_key, "MinorVersion")
        version = majorvalue + minorvalue / 10.0
        versions.append(version)
    
    if not versions:
        raise ValueError("Intel FORTRAN compiler not found")
        
    return max(versions)


def get_vs_version():
    
    cmd = '"%ProgramFiles(x86)%\\Microsoft Visual Studio\\Installer\\vswhere.exe"'
    result = subprocess.check_output(cmd, shell=True)
    lines = result.split(b"\n")
    for line in lines:
        words = line.split(b":")
        if words[0] == b"catalog_productLineVersion":
            return int(words[1])
    raise ValueError("Visual Studio not found")


def get_net_version():
    
    key = "SOFTWARE\\Wow6432Node\\Microsoft\\NET Framework Setup\\NDP\\v4\\Full"
    registry_key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE,
                                  key,
                                  0,
                                  winreg.KEY_READ)
    value, regtype = winreg.QueryValueEx(registry_key, "Release")
    
    if value < netcodes[0]:
        raise ValueError(".NET version not recognised")
    
    j = len(netcodes)
    
    for i, x in enumerate(netcodes):
        if x > value:
            j = i
            break
    
    return netversions[j - 1]


def getUCRTSDKdir(vs):
    
    vsintalldir = "VS{}INSTALLDIR".format(vs)
    getucrtdir = (
        '"'
        + str(os.environ.get(vsintalldir))
        + "\\VC\\Auxiliary\\Build\\vcvarsall.bat"
        + '" amd64&&set UniversalCRTSdkDir'
    )
    
    sys.stdout.write("Trying to execute: " + getucrtdir + " ...\n")
    try:
        result = subprocess.check_output(getucrtdir, shell=True)
    except:
        result = ""
        sys.stdout.write(
            "\n\n *** ERROR:Execution failed; is VisualStudio "
            + str(vs)
            + " installed?\n\n\n"
        )
    result = result.decode("utf-8")
    
    return result


def getUCRTlibdir(vs):
    
    ucrtlibdir = {}
    ucrtlibtemplate = "$(UniversalCRTSdkDir)Lib\\{}\\ucrt\\{}"
    
    # Only for VS2015 or higher
    if vs < 2015:
        return "$(OSS_UCRTLIBDIR)"
    
    # To get the ucrt directory: execute the matching getucrtdir string,
    # catch the stdout of that command,
    # check whether UniversalCRTSdkDir is in that string,
    # if so, get the value behind the '='-sign
    result = getUCRTSDKdir(vs)
    
    if result.find("UniversalCRTSdkDir") == -1:
        # Fallback: it should be this:
        sys.stdout.write("ucrtdir not found; set to default value\n")
        ucrtdir = "c:\\Program Files (x86)\\Windows Kits\\10\\Lib\\"
    else:
        ucrtdir = result[19:]
        # result may be:
        # ****\nbladibla\n****\nUniversalCRTSdkDir=<value>
        # Get the value
        ucrtpos = ucrtdir.rfind("UniversalCRTSdkDir=")
        if ucrtpos > -1:
            ucrtdir = ucrtdir[ucrtpos + 19 :]
        # Remove the trailing slash and the newline-character behind it
        lastslash = ucrtdir.rfind("\\")
        if lastslash != -1:
            ucrtdir = ucrtdir[:lastslash]
        sys.stdout.write("ucrtdir found: " + ucrtdir + "\n")
    # Search in subdir Lib for directories starting with a digit and 
    # containing at least one "."
    searchstring = os.path.join(ucrtdir, "Lib", "[0-9]*.*")
    versions = glob.glob(searchstring)
    if len(versions) <= 0:
        # Fallback: it should be this:
        ucrtversion = "10.0.10586.0"
        sys.stdout.write(
            "No versions found, using default version:" + ucrtversion + "\n"
        )
    else:
        # Choose the highest version number
        versions.sort(reverse=True)
        ucrtversion = versions[0]
        ucrtversion = os.path.basename(ucrtversion)
        sys.stdout.write("Versions found, using: " + ucrtversion + "\n")
    
    # Inside ucrtlibdir, replace all occurences of UCRTLIBDIRVERSIONNUMBER by 
    # ucrtversion
    ucrtlibdir[32] = str(ucrtlibtemplate).format(ucrtversion, "x86")
    ucrtlibdir[64] = str(ucrtlibtemplate).format(ucrtversion, "x64")

    return ucrtlibdir


# process_solution_file ====================================
# process a VisualStudio Solution File (and underlying projects)
# Pass only file names, no full path names. It assumed that both
# files are in fixed locations (see below).
def process_solution_file(sln, slntemplate, vs, fw, ifort, xe, ucrtlibdir):
    
    # Copy the solution template file to the solution file
    sys.stdout.write("Creating file " + sln + " ...\n")
    scriptdir = os.path.dirname(os.path.abspath(__file__))
    topdir = scriptdir
    
    # target file:
    sln = os.path.join(topdir, sln)
    
    # source template file:
    slntemplate = os.path.join(topdir, slntemplate)
    
    shutil.copyfile(slntemplate, sln)
    
    # Collect the project files referenced in the solution file
    projectfiles = []
    # Read sln file:
    # Put the full file contents in filin_contents
    with open(sln, "r", encoding="utf-8") as filinhandle:
        filin_contents = filinhandle.readlines()
    
    # Scan the contents and rewrite the full solution file
    with open(sln, "w", encoding="utf-8") as filouthandle:
        for line in filin_contents:
            # Search for project file references
            pp = line.split('"')
            for subline in pp:
                if (
                    max(
                        subline.find(".vfproj"),
                        subline.find(".vcxproj"),
                        subline.find(".vcproj"),
                        subline.find(".csproj"),
                    )
                    != -1
                ):
                    projectfiles.append(subline)
            # Changes to the sln file based on VS version
            startpos = line.find(
                "Microsoft Visual Studio Solution File, Format Version"
            )
            if startpos == 0:
                if vs == 2010:
                    line = "Microsoft Visual Studio Solution File, Format Version 11.00\r\n"
                elif vs == 2012:
                    line = "Microsoft Visual Studio Solution File, Format Version 12.00\r\n"
                elif vs == 2013:
                    line = "Microsoft Visual Studio Solution File, Format Version 12.00\r\n"
                elif vs == 2014:
                    line = "Microsoft Visual Studio Solution File, Format Version 12.00\r\n"
                elif vs == 2015:
                    line = "Microsoft Visual Studio Solution File, Format Version 12.00\r\n"
                elif vs == 2016:
                    line = "Microsoft Visual Studio Solution File, Format Version 12.00\r\n"
                elif vs == 2017:
                    line = "Microsoft Visual Studio Solution File, Format Version 12.00\r\n"
                elif vs == 2019:
                    line = "Microsoft Visual Studio Solution File, Format Version 12.00\r\n"
                # else:
                # leave line unchanged
            startpos = line.find("# Visual Studio")
            if startpos == 0:
                if vs == 2010:
                    line = "# Visual Studio 2010\r\n"
                elif vs == 2012:
                    line = "# Visual Studio 2012\r\n"
                elif vs == 2013:
                    line = "# Visual Studio 2013\r\n"
                elif vs == 2014:
                    line = "# Visual Studio 2014\r\n"
                elif vs == 2015:
                    line = "# Visual Studio 2015\r\n"
                elif vs == 2016:
                    line = "# Visual Studio 2016\r\n"
                elif vs == 2017:
                    line = "# Visual Studio 2017\r\n"
                elif vs == 2019:
                    line = "# Visual Studio 2019\r\n"
                # else:
                # leave line unchanged
            filouthandle.write(line)
    
    # Process all project files referenced in the sln file
    for pfile in projectfiles:
        pfile = os.path.join(topdir, pfile)
        sys.stdout.write("Processing file " + pfile + " ...\n")
        if os.path.isfile(pfile):
            process_project_file(pfile, vs, fw, ifort, xe, ucrtlibdir)
        else:
            sys.stdout.write("ERROR: File does not exists:" + pfile + "\n")
    sys.stdout.write("...Finished.\n")
    sys.stdout.write('Ready to be used: "' + sln + '"\n')

# process_project_file ====================================
# process a VisualStudio Project File
def process_project_file(pfile,
                         vs,
                         fw,
                         ifort,
                         xe,
                         ucrtlibdir,
                         remove_petsc=True):
    
    # Type (F/C/C#) and related flags are set based on the file extension
    ptype = "unknown"
    config_tag = "unknown"
    config_val32 = "unknown"
    config_val64 = "unknown"
    compilervar = "$(IFORT_COMPILER{})".format(xe)
    
    if pfile.find("vfproj") != -1:
        ptype = "fortran"
        config_tag = "Configuration Name="
        config_val32 = "Win32"
        config_val64 = "x64"
        redistdir = compilervar + "redist\\{}\\compiler\\&quot"
        mkldir = compilervar + "redist\\{}\\mkl\\&quot"
        libdir = compilervar + "\\compiler\\lib\\{}"
    elif pfile.find("vcxproj") != -1:
        ptype = "c"
        config_tag = "ItemDefinitionGroup Condition="
        config_val32 = "Win32"
        config_val64 = "x64"
        redistdir = compilervar + "redist\\{}\\compiler\\"
        mkldir = compilervar + "redist\\{}\\mkl\\"
        libdir = compilervar + "\\compiler\\lib\\{}"
    elif pfile.find("vcproj") != -1 or pfile.find("csproj") != -1:
        ptype = "csharp"
        config_tag = "PropertyGroup Condition="
        config_val32 = "x86"
        config_val64 = "x64"
    
    # Put the full file contents in filin_contents
    with open(pfile, "r", encoding="utf-8") as filinhandle:
        filin_contents = filinhandle.readlines()
    
    # Scan the contents and rewrite the full file
    configuration = 0
    with open(pfile, "w", encoding="utf-8") as filouthandle:
        for line in filin_contents:
            #
            # ToolsVersion
            # Skip this change when vs=0
            if vs != 0:
                startpos = line.find("ToolsVersion=")
                if startpos != -1:
                    parts = line.split('"')
                    i = 0
                    for part in parts:
                        if part.find("ToolsVersion=") != -1:
                            parts[i + 1] = toolsversion[vs]
                        i += 1
                    line = '"'.join(parts)
            
            # FrameworkVersion
            # Skip this change when fw=0
            if fw != 0:
                startpos = line.find("<TargetFrameworkVersion>")
                
                if startpos != -1:
                    endpos = line.find("</TargetFrameworkVersion>")
                    line = line[: startpos + 25] + fw + line[endpos:]
            
            # PlatformToolSet:
            # Skip this change when vs=0
            # Search for line with <PlatformToolset>
            if vs != 0:
                startpos = line.find("<PlatformToolset>")
                if startpos != -1:
                    endpos = line.find("</PlatformToolset>")
                    line = (
                        line[: startpos + 17]
                        + "Intel C++ Compiler {}".format(ifort)
                        + line[endpos:]
                    )
            
            # config_tag, to set configuration
            startpos = line.find(config_tag)
            if startpos != -1:
                if line.find(config_val32) != -1:
                    configuration = 32
                    arch = "ia32"
                elif line.find(config_val64) != -1:
                    configuration = 64
                    arch = "intel64"
            
            # IFORT_COMPILER ...
            startpos = line.find("$(IFORT_COMPILER")
            if startpos != -1:
                if xe == -999:
                    sys.exit(
                        "ERROR: Fortran compiler specification is being used "
                        "while not defined.")
                split_char = ";"
                if line.find("oss-install") != -1:
                    #
                    # ... in argument of oss-install
                    if ptype == "c":
                        split_char = '"'
                    parts = line.split(split_char)
                    i = 0
                    lastFound = -1
                    it = 0
                    for part in parts:
                        lastFound = part.find(
                            "$(IFORT_COMPILER", lastFound + 1
                        )
                        if lastFound != -1:
                            tempStr = ""
                            while lastFound != -1:
                                if it == 0:
                                    tempStr += redistdir.format(arch)
                                    lastFound = part.find(
                                        "$(IFORT_COMPILER", lastFound + 1
                                    )
                                elif it == 1:
                                    tempStr += mkldir.format(arch)
                                    lastFound = part.find(
                                        "$(IFORT_COMPILER", lastFound + 1
                                    )
                                elif it > 1:
                                    break
                                it += 1
                            parts[i] = tempStr
                            i += 1
                        else:
                            parts[i] = part
                            i += 1
                    del parts[i:]
                    line = split_char.join(parts)
                if line.find("AdditionalLibraryDirectories") != -1:
                    # ... in specification of AdditionalLibrarieDirectories
                    parts = line.split(split_char)
                    added = False
                    i = 0
                    for part in parts:
                        startpos = part.find("$(IFORT_COMPILER")
                        if startpos != -1:
                            if not added:
                                parts[i] = parts[i][:startpos] + libdir.format(
                                    arch
                                )
                                added = True
                                i += 1
                            # else:
                            # remove this part
                        else:
                            parts[i] = part
                            i += 1
                    del parts[i:]
                    line = split_char.join(parts)
                else:
                    # Unclear context of using IFORT_COMPILER
                    # Just replace the version number at the end
                    startpos = startpos + 16
                    endpos = startpos + 2
                    line = line[:startpos] + str(xe) + line[endpos:]
            
            # UCRTlibdir
            # Search string to be replaced: two options: "$(OSS_UCRTLIBDIR)" 
            # and "$(UniversalCRTSdkDir)lib\..."
            #
            # $(OSS_UCRTLIBDIR) => $(UniversalCRTSdkDir)lib\...
            startpos = line.find("$(OSS_UCRTLIBDIR)")
            if startpos != -1:
                endpos = startpos + 17
            else:
                # $(UniversalCRTSdkDir)lib\... => $(OSS_UCRTLIBDIR)
                startpos = line.find("$(UniversalCRTSdkDir)")
                if startpos != -1:
                    quotepos = line[startpos:].find('"')
                    if quotepos == -1:
                        quotepos = 999
                    colonpos = line[startpos:].find(";")
                    if colonpos == -1:
                        colonpos = 999
                    endpos = startpos + min(quotepos, colonpos)
            # Replace by the correct string. Assumption: 
            # "UCRTLIBDIRVERSIONNUMBER" is replaced by the correct
            # versionnumber when applicable, by executing getUCRTlibdir
            if startpos != -1:
                line = (
                    line[:startpos] + ucrtlibdir[configuration] + line[endpos:]
                )
            
            # Remove PETSC
            if remove_petsc:
                startpos = line.find("HAVE_PETSC;")
                if startpos != -1:
                    endpos = startpos + 11
                    line = line[:startpos] + line[endpos:]
            
            filouthandle.write(line)


def main(templateSolutionPath=""):
    
    vs = get_vs_version()
    fw = get_net_version()
    ifort = get_highest_compiler_version()
    xe = get_highest_xe_version()
    
    UCRTlibdir = getUCRTlibdir(vs)
    scripts64 =  os.path.join("scripts_lgpl", "win64")
    
    conf_process = lambda fout, fin: process_solution_file(fout,
                                                           fin,
                                                           vs,
                                                           fw,
                                                           ifort,
                                                           xe,
                                                           UCRTlibdir)
    
    if not templateSolutionPath:
        
        conf_process("delft3d_open.sln",
                     os.path.join("scripts_lgpl",
                                  "win64",
                                  "delft3d_open_template.sln"))
        conf_process("dflowfm_open.sln",
                     os.path.join("engines_gpl",
                                  "dflowfm",
                                  "scripts",
                                  "template",
                                  "dflowfm_open_template.sln"))
        conf_process("dimr_open.sln",
                     os.path.join("engines_gpl",
                                  "dimr",
                                  "scripts",
                                  "template",
                                  "dimr_open_template.sln"))
        
        # TODO: Consider making this optional via cmdline args:
        conf_process("io_netcdf.sln",
                     os.path.join(scripts64, "io_netcdf_template.sln"))
        conf_process("nefis.sln",
                     os.path.join(scripts64, "nefis_template.sln"))
        conf_process("utils_lgpl.sln",
                     os.path.join(scripts64, "utils_lgpl_template.sln"))
        conf_process("tests.sln",
                     os.path.join(scripts64, "tests_template.sln"))
    
    else:
        
        slnName = os.path.basename(templateSolutionPath).replace(
                                                        "_template", "")
        conf_process(slnName, templateSolutionPath)
    
    conf_process("ec_module.sln",
                 os.path.join(scripts64, "ec_module_template.sln"))
    
    sys.stdout.write("\n")
    sys.stdout.write("Visual Studio  Version : " + str(vs) + "\n")
    sys.stdout.write(".Net Framework Version : " + str(fw) + "\n")
    sys.stdout.write("Intel Fortran  Version : " + str(ifort) + "\n")
    sys.stdout.write("Parallel Studio XE Version : " + str(xe) + "\n")
    sys.stdout.write("Solution path : " + templateSolutionPath + "\n")
    
    return

if __name__ == "__main__":
    main()
