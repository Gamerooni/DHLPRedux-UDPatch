#r "nuget: Mutagen.Bethesda, 0.45.1"
#r "nuget: Mutagen.Bethesda.Core, 0.45.1"
#r "nuget: Mutagen.Bethesda.Skyrim, 0.45.1"

using Mutagen.Bethesda;
using Mutagen.Bethesda.Plugins;
using Mutagen.Bethesda.Plugins.Records;
using Mutagen.Bethesda.Skyrim;
using Mutagen.Bethesda.Environments;
using Mutagen.Bethesda.Plugins.Cache;
using Mutagen.Bethesda.Plugins.Binary.Parameters;
using Mutagen.Bethesda.Plugins.Order;
using System.Reflection;
using Mutagen.Bethesda.Plugins.Cache.Internals.Implementations;

// General process for creating a mod
var mod = SkyrimMod.CreateFromBinary(
    ModPath.FromPath("DHLP_Redux.esp"),
    release: SkyrimRelease.SkyrimSE
);


// We must turn the mod to a linkCache before we can do anything
ILinkCache scriptLinkCache = mod.ToMutableLinkCache();

public bool TryDeleteRecordByEditorId(string editorId, Type recordType) {
    MethodInfo resolveInfoGeneric = typeof(ILinkCache)
            .GetMethods()
            .FirstOrDefault(
                x => x.Name.Equals("TryResolve", StringComparison.OrdinalIgnoreCase)
                && x.IsGenericMethod
                && x.GetParameters().Length == 2
            )
            ?.MakeGenericMethod(recordType);
    // MethodInfo resolveInfo = typeof(ImmutableModLinkCache).GetMethod(nameof(ImmutableModLinkCache.TryResolve<>));
    // MethodInfo resolveInfoGeneric = resolveInfo.MakeGenericMethod(recordType);
    object[] parameters = [editorId, null];
    if ((bool)resolveInfoGeneric.Invoke(scriptLinkCache, parameters)) {
        MajorRecord majorRecord = (MajorRecord)parameters[1];
        // delete it
        mod.Remove(majorRecord);
        return true;
    } else {
        return false;
    }
}

var recordsToDelete = new Dictionary<string, Type>() {
    {"WD_beltRusted_script", typeof(Armor)},
    {"WD_beltRusted_inv", typeof(Armor)},
    {"WD_beltRustedAA", typeof(ArmorAddon)},
    {"wd_rustedKey", typeof(Key)},
    {"wd_rKeyList", typeof(LeveledItem)},
    {"LootDraugrChestBossBase", typeof(LeveledItem)},
    {"DeathItemSkeleton", typeof(LeveledItem)},
    {"LootDraugrRandom", typeof(LeveledItem)},
    {"WD_rustyKeyDestroyMsg", typeof(Message)},
    {"WD_rustyBeltMsg", typeof(Message)},
    {"WD_beltRustedTexture", typeof(TextureSet)},
};

foreach (var record in recordsToDelete) {
    TryDeleteRecordByEditorId(record.Key, record.Value);
}

var creaturesQuest = scriptLinkCache.Resolve<IQuest>("WD_Creatures");

if (creaturesQuest.VirtualMachineAdapter?.Scripts != null) {
    foreach (var script in creaturesQuest.VirtualMachineAdapter?.Scripts) {
        script.Properties.RemoveAll(prop => prop.Name == "rustedBeltMsg");
    }
}

// Write to patch
mod.WriteToBinary(
    "DHLP_Redux.esp",
    param: new BinaryWriteParameters() {
        ModKey = ModKeyOption.CorrectToPath
    }
);
