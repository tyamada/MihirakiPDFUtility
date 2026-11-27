"""Explicit network integration test; never included in ordinary offline unit runs.
Copies the current developer sources to an external build workspace. Use a dedicated
empty simulator; this test downloads ~100 MB and retains its sandbox cache for UI checks.
"""
import argparse
from pathlib import Path
import shutil
import subprocess
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--source',type=Path,required=True)
p.add_argument('--workspace',type=Path,required=True)
p.add_argument('--manifest',type=Path,required=True)
p.add_argument('--simulator-id',required=True)
a=p.parse_args()
source=a.source.resolve();work=a.workspace.resolve()
if not (source/"MihirakiPDFUtilityApp/SamplePDFManifest.swift").exists():
    raise ValueError("This integration test requires the developer manifest-refresh implementation")
if work==source or source in work.parents or work.exists():
    raise ValueError('Use a new workspace outside the source repository')
work.mkdir(parents=True)
for name in ['MihirakiPDFUtilityApp','MihirakiPDFUtilityTests','MihirakiPDFUtility.xcodeproj']:
    shutil.copytree(source/name,work/name)
shutil.copy2(source/'MihirakiPDFUtility-Info.plist',work/'MihirakiPDFUtility-Info.plist')
shutil.copy2(Path(__file__).with_name('Episode4IntegrationTests.swift'),work/'MihirakiPDFUtilityTests/Episode4IntegrationTests.swift')
shutil.copy2(a.manifest,work/'MihirakiPDFUtilityTests/episode4-manifest-fixture.json')
subprocess.run(['xcodebuild','test','-project',str(work/'MihirakiPDFUtility.xcodeproj'),'-scheme','MihirakiPDFUtility','-destination',f'platform=iOS Simulator,id={a.simulator_id}','-derivedDataPath',str(work/'DerivedData'),'-parallel-testing-enabled','NO','-only-testing:MihirakiPDFUtilityTests/Episode4IntegrationTests','-only-testing:MihirakiPDFUtilityTests/SamplePDFManifestTests','CODE_SIGNING_ALLOWED=NO'],check=True)
