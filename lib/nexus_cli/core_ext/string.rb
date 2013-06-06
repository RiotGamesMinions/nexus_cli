class String
  def to_artifact_hash
    split_self = self.split(':')
    raise NexusCli::ArtifactMalformedException if split_self.size < 3
    {
      g: split_self[0],
      a: split_self[1],
      v: split_self[2],
      e: split_self[3] ? split_self[3] : "jar"
    }
  end
end
